FROM registry.access.redhat.com/ubi8/openjdk-11:latest
USER root
WORKDIR /build
RUN mkdir -p .mvn/wrapper
COPY mvnw* .
COPY .mvn/wrapper .mvn/wrapper
COPY pom.xml .
RUN ./mvnw dependency:go-offline
COPY src src
RUN ./mvnw package
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.3
ARG JAVA_PACKAGE=java-11-openjdk-headless
ARG RUN_JAVA_VERSION=1.3.8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en'
RUN microdnf install curl ca-certificates ${JAVA_PACKAGE}     && microdnf update     && microdnf clean all     && mkdir /deployments     && chown 1001 /deployments     && chmod "g+rwX" /deployments     && chown 1001:root /deployments     && curl https://repo1.maven.org/maven2/io/fabric8/run-java-sh/${RUN_JAVA_VERSION}/run-java-sh-${RUN_JAVA_VERSION}-sh.sh -o /deployments/run-java.sh     && chown 1001 /deployments/run-java.sh     && chmod 540 /deployments/run-java.sh     && echo "securerandom.source=file:/dev/urandom" >> /etc/alternatives/jre/lib/security/java.security
ENV JAVA_OPTIONS="-Dquarkus.http.host=0.0.0.0 -Dquarkus.http.port=8081 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
COPY --from=0 --chown=1001 /build/target/quarkus-app/lib/ /deployments/lib/
COPY --from=0 --chown=1001 /build/target/quarkus-app/*.jar /deployments/
COPY --from=0 --chown=1001 /build/target/quarkus-app/app/ /deployments/app/
COPY --from=0 --chown=1001 /build/target/quarkus-app/quarkus/ /deployments/quarkus/
EXPOSE 8081
USER 1001
ENTRYPOINT ["/deployments/run-java.sh"]

