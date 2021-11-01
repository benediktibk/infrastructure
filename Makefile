#!/usr/bin/make -f

SECRETSDECRYPT := openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in secrets.tar.gz.enc | tar xz
SECRETSENCRYPT := openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in build/secrets.tar.gz -out secrets.tar.gz.enc
COMMONDEPS := build/guard Makefile
ENVIRONMENTFILES := build/sql.env build/valheim.env build/corona.env

############ general

all: images tests

clean:
	git clean -xdff
	
run-locally: images $(ENVIRONMENTFILES)
	docker-compose -f docker-compose.yml up
	
clean-data: $(ENVIRONMENTFILES)
	docker rm -f $(shell docker ps -a -q)
	docker volume rm sqldata
	docker volume rm coronadata
	docker volume rm valheimdata
	
init-data: build/database-server-id.txt build/sql.env
	docker volume create sqldata
	docker volume create coronadata
	docker volume create valheimdata
	./initialize-database.sh

build/guard: Makefile
	mkdir -p build
	mkdir -p build/servers
	mkdir -p build/servers/database
	mkdir -p build/servers/homepage
	mkdir -p build/servers/homepage/bin
	mkdir -p build/servers/corona
	mkdir -p build/servers/corona/viewer
	mkdir -p build/servers/corona/viewer/bin
	mkdir -p build/servers/corona/updater
	mkdir -p build/servers/corona/updater/bin
	mkdir -p build/servers/valheim
	mkdir -p build/servers/valheim/bin
	mkdir -p build/servers/reverse-proxy
	touch $@

tests:
	cd servers/corona/Corona && dotnet test
	
.PHONY: all clean init-data clean-data run-locally images secrets-encrypt build/secrets.tar.gz tests
	 
############ container	

images: build/valheim-id.txt build/database-server-id.txt build/homepage-id.txt build/corona-viewer-id.txt build/corona-updater-id.txt build/reverse-proxy-id.txt
	
build/valheim-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-valheim
	cp dockerfiles/Dockerfile-valheim build/servers/valheim/Dockerfile
	cp servers/valheim/start_server.sh build/servers/valheim/start_server.sh
	cp -R ~/.steam/debian-installation/steamapps/common/Valheim\ dedicated\ server/* build/servers/valheim/bin/
	docker build -t benediktschmidt.at/valheim build/servers/valheim
	docker images --format "{{.ID}}" benediktschmidt.at/valheim > $@
	
build/database-server-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-database
	cp dockerfiles/Dockerfile-database build/servers/database/Dockerfile
	docker build -t benediktschmidt.at/database-server build/servers/database
	docker images --format "{{.ID}}" benediktschmidt.at/database-server > $@
	
build/homepage-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-homepage
	cp dockerfiles/Dockerfile-homepage build/servers/homepage/Dockerfile
	cp -R servers/homepage/me build/servers/homepage/bin
	docker build -t benediktschmidt.at/me build/servers/homepage
	docker images --format "{{.ID}}" benediktschmidt.at/homepage > $@
	
build/corona-viewer-id.txt: $(COMMONDEPS) build/servers/corona/viewer/bin/CoronaSpreadViewer.dll dockerfiles/Dockerfile-corona-viewer
	cp dockerfiles/Dockerfile-corona-viewer build/servers/corona/viewer/Dockerfile
	docker build -t benediktschmidt.at/corona-viewer build/servers/corona/viewer
	docker images --format "{{.ID}}" benediktschmidt.at/corona-viewer > $@

build/corona-updater-id.txt: $(COMMONDEPS) build/servers/corona/updater/bin/Updater.dll dockerfiles/Dockerfile-corona-updater
	cp dockerfiles/Dockerfile-corona-updater build/servers/corona/updater/Dockerfile
	cp corona-updater.sh build/servers/corona/updater/corona-updater.sh
	docker build -t benediktschmidt.at/corona-updater build/servers/corona/updater
	docker images --format "{{.ID}}" benediktschmidt.at/corona-updater > $@
	
build/reverse-proxy-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-reverse-proxy servers/reverse-proxy/default.conf.template servers/reverse-proxy/nginx-start.sh
	cp dockerfiles/Dockerfile-reverse-proxy build/servers/reverse-proxy/Dockerfile
	cp servers/reverse-proxy/default.conf.template build/servers/reverse-proxy/
	cp servers/reverse-proxy/nginx-start.sh build/servers/reverse-proxy/nginx-start.sh
	docker build -t benediktschmidt.at/reverse-proxy build/servers/reverse-proxy
	docker images --format "{{.ID}}" benediktschmidt.at/reverse-proxy > $@	
	

############ environment definitions
	
build/sql.env: environments/sql.env.in build/secrets/passwords/db_sa $(COMMONDEPS)
	cp $< $@
	$(eval SA_PASSWORD := $(shell cat build/secrets/passwords/db_sa))
	sed -i "s/##SA_PASSWORD##/${SA_PASSWORD}/g" $@

build/valheim.env: environments/valheim.env.in build/secrets/passwords/valheim $(COMMONDEPS)
	cp $< $@
	$(eval SERVER_PASSWORD := $(shell cat build/secrets/passwords/valheim))
	sed -i "s/##SERVER_PASSWORD##/$(SERVER_PASSWORD)/g" $@

build/corona.env: environments/corona.env.in build/secrets/passwords/db_corona $(COMMONDEPS)
	cp $< $@
	$(eval DBCORONAPASSWORD := $(shell cat build/secrets/passwords/db_corona))
	sed -i "s/##DBCORONAPASSWORD##/${DBCORONAPASSWORD}/g" $@


############ apps

build/servers/corona/viewer/bin/CoronaSpreadViewer.dll: $(COMMONDEPS) $(shell find servers/corona/Corona -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*")
	dotnet publish servers/corona/Corona/CoronaSpreadViewer --output build/servers/corona/viewer/bin --configuration Release --runtime linux-x64
	touch $@
	
build/servers/corona/updater/bin/Updater.dll: $(COMMONDEPS) $(shell find servers/corona/Corona -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*")
	dotnet publish servers/corona/Corona/Updater --output build/servers/corona/updater/bin --configuration Release --runtime linux-x64
	touch $@

	
############ secrets

build/secrets/guard:
	mkdir -p build
	mkdir -p build/secrets
	touch $@

secrets-encrypt: Makefile build/secrets.tar.gz
	$(SECRETSENCRYPT)

build/secrets.tar.gz: Makefile
	rm -f $@
	tar -czvf $@ build/secrets

build/secrets/passwords/db_sa: build/secrets/guard secrets.tar.gz.enc
	$(SECRETSDECRYPT)
	touch --no-create build/secrets/passwords/*
	
build/secrets/passwords/db_corona: build/secrets/guard secrets.tar.gz.enc
	$(SECRETSDECRYPT)
	touch --no-create build/secrets/passwords/*
	
build/secrets/passwords/valheim: build/secrets/guard secrets.tar.gz.enc
	$(SECRETSDECRYPT)
	touch --no-create build/secrets/passwords/*