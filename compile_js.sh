while true 
do
  inotifywait -e modify assets/main.coffee 
  echo "compiling `date`"
  coffee -c assets/main.coffee
done
