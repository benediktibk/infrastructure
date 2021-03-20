#!/usr/bin/make -f

all: images

clean:
	rm -Rf servers/valheim/build
	rm -Rf servers/tester/build

images: build/valheim-id.txt build/database-server-id.txt build/mssql-client-id.txt build/homepage-id.txt build/tester-id.txt
	
build/valheim-id.txt: servers/valheim/Dockerfile
	mkdir -p build
	mkdir -p servers/valheim/build
	cp -R "~/.local/share/Steam/steamapps/common/Valheim\ dedicated\ server/*" servers/valheim/build/
	docker build -t benediktschmidt.at/valheim servers/valheim
	docker images --format "{{.ID}}" benediktschmidt.at/valheim > $@
	
build/database-server-id.txt: servers/database-server/Dockerfile
	mkdir -p build
	docker build --build-arg SA_PASSWORD=${BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD} -t benediktschmidt.at/database-server servers/database-server
	docker images --format "{{.ID}}" benediktschmidt.at/database-server > $@
	
build/mssql-client-id.txt: servers/mssql-client/Dockerfile
	mkdir -p build
	docker build -t benediktschmidt.at/mssql-client servers/mssql-client
	docker images --format "{{.ID}}" benediktschmidt.at/mssql-client > $@
	
build/homepage-id.txt: servers/homepage/Dockerfile
	mkdir -p build
	docker build -t benediktschmidt.at/me servers/homepage
	docker images --format "{{.ID}}" benediktschmidt.at/homepage > $@
	
build/tester-id.txt: servers/tester/Dockerfile docker-compose.yml *.env
	mkdir -p build
	mkdir -p servers/tester/build
	cp docker-compose.yml servers/tester/build/
	cp *.env servers/tester/build/
	docker build -t benediktschmidt.at/tester servers/tester
	docker images --format "{{.ID}}" benediktschmidt.at/tester > $@
		
run-tester: images
	docker run --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock benediktschmidt.at/tester
