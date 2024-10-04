require 'minitest/autorun'
load '../authority.rb'
load '../lib/ifc/manager.rb'

class TestCase < Minitest::Test

  def port
    ENV["PORT"] || 4567
  end

  def setup
    @ifc_ms1 = Ifc::Manager.new("http://localhost:#{port}", 'ms1.pem')
    @ifc_ms2 = Ifc::Manager.new("http://localhost:#{port}", 'ms2.pem')
    @ifc_not_present = Ifc::Manager.new("http://localhost:#{port}", 'not_present.pem')
  end

  def assert_add_confidentiality_is_successful(data)
    assert data[:key]
    assert data[:iv]
    assert data[:data]
    assert data[:authority_metadata_depth]
  end

  def assert_add_integrity_is_successful(data)
    assert data[:integrity_tags]
    assert data[:signature]
    assert data[:data]
    assert @ifc_ms1.check_integrity(data.to_json)
  end

  def test_should_be_able_to_add_and_remove_confidentiality_from_raw_data
    data = 'data'
    encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(data, [:tag1_conf, :tag2_conf]), symbolize_names: true)
    assert_add_confidentiality_is_successful(encrypted_data)
    response_data = @ifc_ms1.remove_confidentiality(encrypted_data.to_json)
    assert_equal data, JSON.parse(response_data, symbolize_names: true)[:data]
  end

  def test_should_be_able_to_add_and_remove_integrity_from_raw_data
    data = 'data'
    integrity_data = JSON.parse(@ifc_ms1.add_integrity(data, [:tag1_conf, :tag2_conf]), symbolize_names: true)
    assert_add_integrity_is_successful(integrity_data)
    response_data = @ifc_ms1.remove_integrity(integrity_data.to_json)
    assert_equal data, JSON.parse(response_data, symbolize_names: true)[:data]
  end

  def test_should_be_able_to_add_and_remove_integrity_from_confidential_data
    data = 'data'
    integrity_data = JSON.parse(@ifc_ms1.add_integrity(data, [:tag1_conf, :tag2_conf]), symbolize_names: true)
    assert_add_integrity_is_successful(integrity_data)
    new_data = @ifc_ms1.remove_integrity(integrity_data.to_json)
    assert_equal data, JSON.parse(new_data, symbolize_names: true)[:data]
  end

  def test_should_be_able_to_add_and_remove_integrity_from_integrity_data
    data = 'data'
    integrity_data = JSON.parse(@ifc_ms1.add_integrity(data, [:tag1_conf, :tag2_conf]), symbolize_names: true)
    assert_add_integrity_is_successful(integrity_data)
    integrity_data = JSON.parse(@ifc_ms1.add_integrity(integrity_data.to_json, [:tag3_conf, :tag4_conf]), symbolize_names: true)
    assert_add_integrity_is_successful(integrity_data)
    assert_equal integrity_data[:integrity_tags], [:tag1_conf, :tag2_conf, :tag3_conf, :tag4_conf].map(&:to_s)
    response_data = @ifc_ms1.remove_integrity(integrity_data.to_json)
    assert_equal data, JSON.parse(response_data, symbolize_names: true)[:data]
  end

  def test_should_not_verify_signature_if_information_or_tags_were_changed
    data = 'data'
    integrity_data = JSON.parse(@ifc_ms1.add_integrity(data, [:tag1_conf, :tag2_conf]), symbolize_names: true)
    assert_add_integrity_is_successful(integrity_data)
    changed_integrity_data = integrity_data.dup
    changed_integrity_data[:data] = "another data"
    refute @ifc_ms1.check_integrity(changed_integrity_data.to_json)
    changed_integrity_data = integrity_data.dup
    changed_integrity_data[:integrity_tags] = ["tag1", "tag2"]
    refute @ifc_ms1.check_integrity(changed_integrity_data.to_json)
  end

  def test_should_be_able_to_add_confidentiality_to_confidential_data
    data = 'data'
    encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(data, [:tag1_conf]), symbolize_names: true)
    assert_add_confidentiality_is_successful(encrypted_data)
    encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(data, [:tag2_conf]), symbolize_names: true)
    assert_add_confidentiality_is_successful(encrypted_data)
    response_data = @ifc_ms1.remove_confidentiality(encrypted_data.to_json)
    assert_equal data, JSON.parse(response_data, symbolize_names: true)[:data]
  end

  def test_should_be_able_to_add_integrity_to_confidential_data
    data = 'data'
    encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(data, [:tag1_conf]), symbolize_names: true)
    assert_add_confidentiality_is_successful(encrypted_data)
    integrity_data = JSON.parse(@ifc_ms1.add_integrity(encrypted_data.to_json, [:tag1_conf, :tag2_conf]), symbolize_names: true)
    assert_add_integrity_is_successful(integrity_data)
    response_data = @ifc_ms1.remove_confidentiality(integrity_data.to_json)
    assert_equal data, JSON.parse(response_data, symbolize_names: true)[:data]
  end

  def test_should_support_multiple_confidentiality_and_integrity_adding
    data = 'data'
    original_data = data
    conf_to_add = [:tag1_conf, :tag2_conf, :tag3_conf]
    int_to_add = [:tag1_int, :tag2_int, :tag3_int]
    3.times do |i|
      encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(data, [conf_to_add[i]]), symbolize_names: true)
      assert_add_confidentiality_is_successful(encrypted_data)
      integrity_data = JSON.parse(@ifc_ms1.add_integrity(encrypted_data.to_json, [int_to_add[i]]), symbolize_names: true)
      assert_add_integrity_is_successful(integrity_data)
      data = integrity_data.to_json
    end
    response_data = @ifc_ms1.remove_confidentiality(data)
    hash_response = JSON.parse(response_data, symbolize_names: true)
    assert_equal hash_response[:data], original_data
    assert_equal int_to_add.map(&:to_s), hash_response[:integrity_tags]
  end

  def test_should_support_multiple_separate_confidentiality_and_integrity_adding
    data = 'data'
    original_data = data
    conf_to_add = [:tag1_conf, :tag2_conf]
    int_to_add = [:tag1_int, :tag2_int]
    2.times do |i|
      encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(data, [conf_to_add[i]]), symbolize_names: true)
      assert_add_confidentiality_is_successful(encrypted_data)
      integrity_data = JSON.parse(@ifc_ms1.add_integrity(encrypted_data.to_json, [int_to_add[i]]), symbolize_names: true)
      assert_add_integrity_is_successful(integrity_data)
      data = integrity_data.to_json
    end

    conf_to_add = [:tag4_conf, :tag5_conf]
    expected_int = []
    expected_int.concat(int_to_add)
    int_to_add = [:tag4_int, :tag5_int]
    expected_int.concat(int_to_add)
    2.times do |i|
      encrypted_data = JSON.parse(@ifc_ms2.add_confidentiality(data, [conf_to_add[i]]), symbolize_names: true)
      assert_add_confidentiality_is_successful(encrypted_data)
      integrity_data = JSON.parse(@ifc_ms2.add_integrity(encrypted_data.to_json, [int_to_add[i]]), symbolize_names: true)
      assert_add_integrity_is_successful(integrity_data)
      data = integrity_data.to_json
    end

    response_data = @ifc_ms1.remove_confidentiality(data)
    hash_response = JSON.parse(response_data, symbolize_names: true)
    assert_equal hash_response[:data], original_data
    assert_equal expected_int.map(&:to_s), hash_response[:integrity_tags]
  end

  def test_should_not_remove_confidentiality_if_integrity_is_broken
    data = 'data'
    original_data = data
    encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(data, [:tag1_conf]), symbolize_names: true)
    assert_add_confidentiality_is_successful(encrypted_data)
    integrity_data = JSON.parse(@ifc_ms1.add_integrity(encrypted_data.to_json, [:tag1_int]), symbolize_names: true)
    assert_add_integrity_is_successful(integrity_data)
    data = integrity_data.to_json
    encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(data, [:tag2_conf]), symbolize_names: true)
    assert_add_confidentiality_is_successful(encrypted_data)
    encrypted_data[:integrity_tags] = [:should_not_be_here]
    encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(encrypted_data.to_json, [:tag2_conf]), symbolize_names: true)
    assert_add_confidentiality_is_successful(encrypted_data)
    assert_raises Ifc::IntegritySignatureError do
      @ifc_ms1.remove_confidentiality(encrypted_data.to_json)
    end
  end

  def test_should_not_add_integrity_if_ms_has_no_tag
    data = 'data'
    assert_raises Ifc::NotPresentOnAlltagsError do
      integrity_data = @ifc_ms1.add_integrity(data, [:not_registered, :not_registered_2])
    end
  end

  def test_should_not_remove_confidentiality_if_ms_doesnt_have_all_tags
    data = 'data'
    encrypted_data = JSON.parse(@ifc_ms1.add_confidentiality(data, [:not_registered, :not_registered_2]), symbolize_names: true)
    assert_add_confidentiality_is_successful(encrypted_data)
    assert_raises Ifc::NotPresentOnAlltagsError do
      response_data = @ifc_ms1.remove_confidentiality(encrypted_data.to_json)
    end
  end

  def test_should_raise_error_if_microservice_is_not_expected_by_authority
    data = 'data'
    encrypted_data = JSON.parse(@ifc_not_present.add_confidentiality(data, [:not_registered, :not_registered_2]), symbolize_names: true)
    assert_add_confidentiality_is_successful(encrypted_data)
    assert_raises Ifc::NoKeyOnDatabaseError do
      response_data = @ifc_not_present.remove_confidentiality(encrypted_data.to_json)
    end
  end
end

