docker stop $(docker ps -q)
cd base && bash run.sh && cd - && \
  cd conf && bash run.sh && cd - &&  \
  cd int && bash run.sh && cd - && \
  cd some_confidentiality && bash run.sh
