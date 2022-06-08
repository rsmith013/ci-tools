FROM python:3.9-slim

# Create a non-root user
ENV APPLICATION_USER=appuser
ENV APPLICATION_USER_HOME=/home/${APPLICATION_USER}
ENV USER_UID=1001
ENV USER_GID=$USER_UID

RUN groupadd --gid ${USER_GID} ${APPLICATION_USER} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home ${APPLICATION_USER}

RUN pip3 install awscli==1.25.3 dnsimple

COPY --chown=${APPLICATION_USER} scripts/ ${APPLICATION_USER_HOME}/scripts/

USER ${USER_UID}

WORKDIR ${APPLICATION_USER_HOME}