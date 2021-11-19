#!/usr/bin/make -f

SECRETSDECRYPT := openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in secrets.tar.gz.enc | tar xz
SECRETSENCRYPT := openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in build/secrets.tar.gz -out secrets.tar.gz.enc
COMMONDEPS := build/guard Makefile
ENVIRONMENTS := sql valheim corona reverse-proxy vpn firewall dc dc-init
ENVIRONMENTFILES := $(addprefix /etc/infrastructure/environments/,$(addsuffix .env,$(ENVIRONMENTS)))
IMAGENAMES := valheim database-server homepage corona-viewer corona-updater corona-init reverse-proxy downloads vpn firewall dc network-util certbot
IMAGEIDS := $(addprefix build/,$(addsuffix -id.txt,$(IMAGENAMES)))
IMAGEPUSHEDIDS := $(addprefix build/,$(addsuffix -pushed-id.txt,$(IMAGENAMES)))
VOLUMES := sql corona valheim downloads webcertificates dc acme
VPNCLIENTCONFIGS = $(shell find servers/vpn/ -iname server-client-*)

CREATEVOLUMES := for volume in $(VOLUMES); do echo "creating volume $$volume"; docker volume create "$$volume"; done;
DELETEVOLUMES := if [ ! -z "$(shell docker ps -a -q)" ]; then docker rm -f $(shell docker ps -a -q); fi; docker volume rm $(VOLUMES)
DOCKERCOMPOSECORONAINIT := docker-compose --project-name infrastructure-init -f compose-files/corona-init.yaml up --abort-on-container-exit
DOCKERCOMPOSESERVER := docker-compose --project-name infrastructure -f compose-files/server.yaml up

############ general

all: $(IMAGEPUSHEDIDS) $(ENVIRONMENTFILES) tests

clean:
	git clean -xdff
	
run: $(IMAGEIDS) $(ENVIRONMENTFILES)
	$(DOCKERCOMPOSESERVER)

deploy-update: $(ENVIRONMENTFILES) $(IMAGEPUSHEDIDS)
	ansible-playbook playbooks/dockerhost-update.yaml
	
data-clean: $(ENVIRONMENTFILES)
	$(DELETEVOLUMES)
	
data-init: $(IMAGEIDS) $(ENVIRONMENTFILES)
	$(CREATEVOLUMES)
	$(DOCKERCOMPOSECORONAINIT)

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
	mkdir -p build/servers/vpn
	mkdir -p build/servers/firewall
	mkdir -p build/servers/dc
	mkdir -p build/servers/network-util
	mkdir -p build/servers/certbot
	touch $@

tests:
	cd servers/corona/Corona && dotnet test
	
.PHONY: all clean data-init data-clean data-clean run-local deploy-update secrets-encrypt build/secrets.tar.gz tests
	 
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
	cp build/secrets/ca/root_ca.crt build/servers/reverse-proxy/root_ca.crt
	docker build -t benediktibk/reverse-proxy build/servers/reverse-proxy
	docker images --format "{{.ID}}" benediktibk/reverse-proxy > $@	
	
build/downloads-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-downloads servers/downloads/default.conf
	cp dockerfiles/Dockerfile-downloads build/servers/downloads/Dockerfile
	cp servers/downloads/default.conf build/servers/downloads/default.conf
	docker build -t benediktibk/downloads build/servers/downloads
	docker images --format "{{.ID}}" benediktibk/downloads > $@
	
build/vpn-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-vpn servers/vpn/server.conf.template servers/vpn/openvpn-start.sh $(VPNCLIENTCONFIGS)
	cp dockerfiles/Dockerfile-vpn build/servers/vpn/Dockerfile
	cp servers/vpn/server.conf.template build/servers/vpn/
	cp servers/vpn/openvpn-start.sh build/servers/vpn
	cp $(VPNCLIENTCONFIGS) build/servers/vpn/
	docker build -t benediktibk/vpn build/servers/vpn
	docker images --format "{{.ID}}" benediktibk/vpn > $@

build/firewall-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-firewall servers/firewall/firewall.sh
	cp dockerfiles/Dockerfile-firewall build/servers/firewall/Dockerfile
	cp servers/firewall/firewall.sh build/servers/firewall/
	docker build -t benediktibk/firewall build/servers/firewall
	docker images --format "{{.ID}}" benediktibk/firewall > $@

build/dc-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-dc servers/dc/smb.conf
	cp dockerfiles/Dockerfile-dc build/servers/dc/Dockerfile
	cp servers/dc/smb.conf build/servers/dc/
	docker build -t benediktibk/dc build/servers/dc
	docker images --format "{{.ID}}" benediktibk/dc > $@

build/network-util-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-network-util servers/network-util/endless-loop.sh
	cp dockerfiles/Dockerfile-network-util build/servers/network-util/Dockerfile
	cp servers/network-util/endless-loop.sh build/servers/network-util/
	docker build -t benediktibk/network-util build/servers/network-util
	docker images --format "{{.ID}}" benediktibk/network-util > $@

build/certbot-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-certbot servers/certbot/certbot.sh
	cp dockerfiles/Dockerfile-certbot build/servers/certbot/Dockerfile
	cp servers/certbot/certbot.sh build/servers/certbot/
	docker build -t benediktibk/certbot build/servers/certbot
	docker images --format "{{.ID}}" benediktibk/certbot > $@
	
build/%-pushed-id.txt: build/%-id.txt
	rm -f $@
	docker push benediktibk/$*
	touch $@

############ environment definitions
	
/etc/infrastructure/environments/sql.env: environments/sql.env.in build/secrets/passwords/db_sa $(COMMONDEPS)
	cp $< $@
	$(eval SA_PASSWORD := $(shell cat build/secrets/passwords/db_sa))
	sed -i "s/##SA_PASSWORD##/${SA_PASSWORD}/g" $@

/etc/infrastructure/environments/valheim.env: environments/valheim.env.in build/secrets/passwords/valheim $(COMMONDEPS)
	cp $< $@
	$(eval SERVER_PASSWORD := $(shell cat build/secrets/passwords/valheim))
	sed -i "s/##SERVER_PASSWORD##/$(SERVER_PASSWORD)/g" $@

/etc/infrastructure/environments/corona.env: environments/corona.env.in build/secrets/passwords/db_corona $(COMMONDEPS)
	cp $< $@
	$(eval DBCORONAPASSWORD := $(shell cat build/secrets/passwords/db_corona))
	sed -i "s/##DBCORONAPASSWORD##/${DBCORONAPASSWORD}/g" $@

/etc/infrastructure/environments/dc-init.env: environments/dc-init.env.in build/secrets/passwords/domainpass $(COMMONDEPS)
	cp $< $@
	$(eval DOMAINPASS := $(shell cat build/secrets/passwords/domainpass))
	sed -i "s/##DOMAINPASS##/${DOMAINPASS}/g" $@

/etc/infrastructure/environments/%.env: environments/%.env
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

build/secrets/guard: secrets.tar.gz.enc
	mkdir -p build
	mkdir -p build/secrets
	$(SECRETSDECRYPT)
	touch $@

secrets-encrypt: Makefile build/secrets.tar.gz
	$(SECRETSENCRYPT)

build/secrets.tar.gz: Makefile
	rm -f $@
	tar -czvf $@ build/secrets

build/secrets/passwords/db_sa: build/secrets/guard
	
build/secrets/passwords/db_corona: build/secrets/guard
	
build/secrets/passwords/valheim: build/secrets/guard