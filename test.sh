docker run -d -v ~/sslca_data:/data -v ~/sslca_config:/config -P --name sslca theit8514/arch-sslca
#docker exec -it -u 0 sslca bash -l
sleep 2
ssh -p $(docker port sslca 2222/tcp | sed 's/^[^:]*:\([^ ]*\).*/\1/g') root@localhost
docker logs sslca
docker stop sslca
docker rm sslca
