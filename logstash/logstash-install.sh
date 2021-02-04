sudo apt install wget -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

sudo apt-get install apt-transport-https -y

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

sudo apt-get update && sudo apt-get install logstash -y

sudo systemctl enable logstash
sudo systemctl start logstash

sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-google_pubsub
sudo /usr/share/logstash/bin/logstash-plugin install microsoft-logstash-output-azure-loganalytics

#DL file from Cloud storage: pipeline config to /etc/logstash/conf.d/