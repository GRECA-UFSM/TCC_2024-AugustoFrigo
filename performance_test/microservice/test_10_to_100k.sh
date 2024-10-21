docker stop $(docker ps -q)
cd base && bash run_for_10_to_100k.sh && cd - && \
  cd conf && bash run_for_10_to_100k.sh && cd - &&  \
  cd int && bash run_for_10_to_100k.sh && cd - && \
  cd some_confidentiality && bash run_for_10_to_100k.sh