FROM grrdocker/grr

EXPOSE 8444
ENV DISABLE_INTERNAL_MYSQL=true
ENV MONITORING_HTTP_PORT=8444
ENV CERTS_PATH=/etc/grr/certs
ENV CA_CERT_PATH=$CERTS_PATH/ca-cert.pem
ENV CA_PRIVATE_KEY_PATH=$CERTS_PATH/ca-private.key

RUN mkdir -p $CERTS_PATH

COPY prepare_certs.sh $GRR_VENV/bin/prepare_certs.sh
COPY config.yaml /etc/grr/server.local.yaml

CMD $GRR_VENV/bin/prepare_certs.sh && \
  $GRR_VENV/bin/grr_server \
  --component worker \
  --secondary_configs /etc/grr/server.local.yaml
