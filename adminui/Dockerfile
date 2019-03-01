FROM grrdocker/grr

RUN apt-get update && \
  apt-get install -y \
  curl \
  jq

EXPOSE 443 
EXPOSE 5222

ENV MONITORING_HTTP_PORT=5222
ENV ADMINUI_PORT=443
ENV ADMINUI_WEBAUTH_MANAGER=BasicWebAuthManager
ENV CERTS_PATH=/etc/grr/certs
ENV FRONTEND_PUBLIC_SIGNING_KEY_PATH=$CERTS_PATH/frontend-signing.pub

RUN mkdir -p $CERTS_PATH

COPY prepare_certs.sh $GRR_VENV/bin/prepare_certs.sh
COPY bootstrap_grr.sh $GRR_VENV/bin/bootstrap_grr.sh
COPY backend_service_id.sh $GRR_VENV/bin/backend_service_id.sh
COPY config.yaml /etc/grr/server.local.yaml

CMD $GRR_VENV/bin/prepare_certs.sh && \
  $GRR_VENV/bin/backend_service_id.sh > /dev/null && \
  CLOUD_BACKEND_SERVICE_ID=$($GRR_VENV/bin/backend_service_id.sh) \
  $GRR_VENV/bin/bootstrap_grr.sh
