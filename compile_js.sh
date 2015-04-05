while true 
do
  inotifywait -e modify assets/coffee/*.coffee 
  echo "compiling `date`"
  coffee -c assets/coffee/*.coffee
done
