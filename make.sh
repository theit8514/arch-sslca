[ "$1" == "clean" ] && docker rmi $(docker images -f 'dangling=true' -q)
docker build --rm=true -t theit8514/arch-sslca .
