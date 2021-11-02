#!/usr/bin/make -f

SECRETSDECRYPT := openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in secrets.tar.gz.enc | tar xz
SECRETSENCRYPT := openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in build/secrets.tar.gz -out secrets.tar.gz.enc
COMMONDEPS := build/guard Makefile
ENVIRONMENTS := sql valheim corona reverse-proxy
ENVIRONMENTFILES := $(addprefix /etc/infrastructure/,$(addsuffix .env,$(ENVIRONMENTS)))
IMAGENAMES := valheim database-server homepage corona-viewer corona-updater corona-init reverse-proxy downloads
IMAGEIDS := $(addprefix build/,$(addsuffix -id.txt,$(IMAGENAMES)))
VOLUMES := sqldata coronadata valheimdata downloadsdata

CONTEXTSWITCHRESULT := $(shell docker context use default)

############ general

all: $(IMAGEIDS) tests

clean:
	git clean -xdff
	
run-local: $(IMAGEIDS) $(ENVIRONMENTFILES)
	docker-compose --project-name infrastructure -f compose-files/server.yml up

run-remote: $(ENVIRONMENTFILES)
	ansible-playbook playbooks/dockerhost-update.yaml
	docker context use server-1
	docker-compose --project-name infrastructure -f compose-files/server.yml up
	docker context use default
	
data-clean-local: $(ENVIRONMENTFILES)
	if [ ! -z "$(shell docker ps -a -q)" ]; then docker rm -f $(shell docker ps -a -q); fi;
	docker volume rm $(VOLUMES)
	
data-clean-remote: $(ENVIRONMENTFILES)
	docker context use server-1
	if [ ! -z "$(shell docker ps -a -q)" ]; then docker rm -f $(shell docker ps -a -q); fi;
	docker volume rm $(VOLUMES)
	docker context use default
	
data-init-local: $(IMAGEIDS) $(ENVIRONMENTFILES)
	for volume in $(VOLUMES); do docker volume create "$(volume)"; done;
	docker-compose --project-name infrastructure-init -f compose-files/server-init.yml up --abort-on-container-exit

data-init-remote: $(IMAGEIDS) $(ENVIRONMENTFILES)
	ansible-playbook playbooks/dockerhost-update.yaml
	docker context use server-1
	for volume in $(VOLUMES); do docker volume create "$(volume)"; done;
	docker-compose --project-name infrastructure-init -f compose-files/server-init.yml up --abort-on-container-exit
	docker context use default

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
	mkdir -p build/servers/corona/init
	mkdir -p build/servers/corona/init/bin
	mkdir -p build/servers/valheim
	mkdir -p build/servers/valheim/bin
	mkdir -p build/servers/reverse-proxy
	mkdir -p build/servers/downloads
	touch $@

tests:
	cd servers/corona/Corona && dotnet test

push: $(IMAGEIDS)
	docker push benediktibk/valheim
	docker push benediktibk/database-server
	docker push benediktibk/homepage
	docker push benediktibk/corona-viewer
	docker push benediktibk/corona-updater
	docker push benediktibk/corona-init
	docker push benediktibk/reverse-proxy
	docker push benediktibk/downloads
	
.PHONY: all clean data-init-local data-init-remote data-clean-local data-clean-remote run-local run-remote secrets-encrypt build/secrets.tar.gz tests push deploy
	 
############ container
	
build/valheim-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-valheim servers/valheim/start_server.sh
	cp dockerfiles/Dockerfile-valheim build/servers/valheim/Dockerfile
	cp servers/valheim/start_server.sh build/servers/valheim/start_server.sh
	cp -R ~/.steam/debian-installation/steamapps/common/Valheim\ dedicated\ server/* build/servers/valheim/bin/
	docker build -t benediktibk/valheim build/servers/valheim
	docker images --format "{{.ID}}" benediktibk/valheim > $@
	
build/database-server-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-database
	cp dockerfiles/Dockerfile-database build/servers/database/Dockerfile
	docker build -t benediktibk/database-server build/servers/database
	docker images --format "{{.ID}}" benediktibk/database-server > $@
	
build/homepage-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-homepage
	cp dockerfiles/Dockerfile-homepage build/servers/homepage/Dockerfile
	cp -R servers/homepage/me build/servers/homepage/bin
	docker build -t benediktibk/homepage build/servers/homepage
	docker images --format "{{.ID}}" benediktibk/homepage > $@
	
build/corona-viewer-id.txt: $(COMMONDEPS) build/servers/corona/viewer/bin/CoronaSpreadViewer.dll dockerfiles/Dockerfile-corona-viewer
	cp dockerfiles/Dockerfile-corona-viewer build/servers/corona/viewer/Dockerfile
	docker build -t benediktibk/corona-viewer build/servers/corona/viewer
	docker images --format "{{.ID}}" benediktibk/corona-viewer > $@

build/corona-updater-id.txt: $(COMMONDEPS) build/servers/corona/updater/bin/Updater.dll dockerfiles/Dockerfile-corona-updater scripts/corona-updater.sh
	cp dockerfiles/Dockerfile-corona-updater build/servers/corona/updater/Dockerfile
	cp scripts/corona-updater.sh build/servers/corona/updater/corona-updater.sh
	docker build -t benediktibk/corona-updater build/servers/corona/updater
	docker images --format "{{.ID}}" benediktibk/corona-updater > $@

build/corona-init-id.txt: $(COMMONDEPS) build/servers/corona/init/bin/Updater.dll dockerfiles/Dockerfile-corona-init scripts/corona-init.sh
	cp dockerfiles/Dockerfile-corona-init build/servers/corona/init/Dockerfile
	cp scripts/corona-init.sh build/servers/corona/init/corona-init.sh
	docker build -t benediktibk/corona-init build/servers/corona/init
	docker images --format "{{.ID}}" benediktibk/corona-init > $@
	
build/reverse-proxy-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-reverse-proxy servers/reverse-proxy/default.conf.template servers/reverse-proxy/nginx-start.sh
	cp dockerfiles/Dockerfile-reverse-proxy build/servers/reverse-proxy/Dockerfile
	cp servers/reverse-proxy/default.conf.template build/servers/reverse-proxy/
	cp servers/reverse-proxy/nginx-start.sh build/servers/reverse-proxy/nginx-start.sh
	docker build -t benediktibk/reverse-proxy build/servers/reverse-proxy
	docker images --format "{{.ID}}" benediktibk/reverse-proxy > $@	
	
build/downloads-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-downloads servers/downloads/default.conf
	cp dockerfiles/Dockerfile-downloads build/servers/downloads/Dockerfile
	cp servers/downloads/default.conf build/servers/downloads/default.conf
	docker build -t benediktibk/downloads build/servers/downloads
	docker images --format "{{.ID}}" benediktibk/downloads > $@
	

############ environment definitions
	
/etc/infrastructure/sql.env: environments/sql.env.in build/secrets/passwords/db_sa $(COMMONDEPS)
	cp $< $@
	$(eval SA_PASSWORD := $(shell cat build/secrets/passwords/db_sa))
	sed -i "s/##SA_PASSWORD##/${SA_PASSWORD}/g" $@

/etc/infrastructure/valheim.env: environments/valheim.env.in build/secrets/passwords/valheim $(COMMONDEPS)
	cp $< $@
	$(eval SERVER_PASSWORD := $(shell cat build/secrets/passwords/valheim))
	sed -i "s/##SERVER_PASSWORD##/$(SERVER_PASSWORD)/g" $@

/etc/infrastructure/corona.env: environments/corona.env.in build/secrets/passwords/db_corona $(COMMONDEPS)
	cp $< $@
	$(eval DBCORONAPASSWORD := $(shell cat build/secrets/passwords/db_corona))
	sed -i "s/##DBCORONAPASSWORD##/${DBCORONAPASSWORD}/g" $@

/etc/infrastructure/reverse-proxy.env: environments/reverse-proxy.env
	cp $< $@


############ apps

build/servers/corona/viewer/bin/CoronaSpreadViewer.dll: $(COMMONDEPS) $(shell find servers/corona/Corona -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*")
	dotnet publish servers/corona/Corona/CoronaSpreadViewer --output build/servers/corona/viewer/bin --configuration Release --runtime linux-x64
	touch $@
	
build/servers/corona/updater/bin/Updater.dll: $(COMMONDEPS) $(shell find servers/corona/Corona -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*")
	dotnet publish servers/corona/Corona/Updater --output build/servers/corona/updater/bin --configuration Release --runtime linux-x64
	touch $@

build/servers/corona/init/bin/Updater.dll: $(COMMONDEPS) $(shell find servers/corona/Corona -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*")
	dotnet publish servers/corona/Corona/Updater --output build/servers/corona/init/bin --configuration Release --runtime linux-x64
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