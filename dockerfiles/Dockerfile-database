FROM mcr.microsoft.com/mssql/server
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Express
EXPOSE 1433/udp
EXPOSE 1433/tcp
RUN mkdir /var/opt/mssql/data
RUN chown mssql /var/opt/mssql/data
