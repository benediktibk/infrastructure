FROM debian
RUN apt update
RUN apt upgrade -y
RUN apt install -y docker
RUN apt install -y docker-compose
RUN apt install -y nano
RUN mkdir -p /opt/tester
COPY build/docker-compose.yml /opt/tester/
COPY build/*.env /opt/tester/
CMD docker-compose -f /opt/tester/docker-compose.yml up
