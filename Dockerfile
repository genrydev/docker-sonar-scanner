FROM openjdk:17-jdk-alpine

LABEL maintainer="genrydev <gleyvaglez@gmail.com>"

# BEGIN alpine-specific
RUN apk add --no-cache curl grep sed unzip bash nodejs nodejs-npm
# END alpine-specific

# non-root user
ENV USER=sonarscanner
ENV UID=12345
ENV GID=23456
RUN addgroup --gid $GID sonarscanner
RUN adduser \
    --disabled-password \
    --gecos "" \
    --ingroup "$USER" \
    --no-create-home \
    --uid "$UID" \
    "$USER"

# Set timezone to CST
ENV TZ=America/Montevideo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /usr/src

ARG SCANNER_VERSION=4.0.0.1744
ENV SCANNER_FILE=sonar-scanner-cli-${SCANNER_VERSION}-linux.zip
ENV SCANNER_EXPANDED_DIR=sonar-scanner-${SCANNER_VERSION}-linux
RUN curl --insecure -o ${SCANNER_FILE} \
    -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/${SCANNER_FILE} && \
	unzip -q ${SCANNER_FILE} && \
	rm ${SCANNER_FILE} && \
	mv ${SCANNER_EXPANDED_DIR} /usr/lib/sonar-scanner && \
	ln -s /usr/lib/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner

ENV SONAR_RUNNER_HOME=/usr/lib/sonar-scanner

ADD Dockerfile /Dockerfile

#COPY sonar-runner.properties /usr/lib/sonar-scanner/conf/sonar-scanner.properties

# ensure Sonar uses the provided Java for musl instead of a borked glibc one
RUN sed -i 's/use_embedded_jre=true/use_embedded_jre=false/g' /usr/lib/sonar-scanner/bin/sonar-scanner

# Separating ENTRYPOINT and CMD operations allows for core execution variables to
# be easily overridden by passing them in as part of the `docker run` command.
# This allows the default /usr/src base dir to be overridden by users as-needed.
CMD ["sonar-scanner", "-Dsonar.projectBaseDir=/usr/src"]
