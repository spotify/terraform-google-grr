#  Copyright 2018-2019 Spotify AB.
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.

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
