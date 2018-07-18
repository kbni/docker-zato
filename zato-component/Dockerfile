FROM zatobase:latest
ARG ZATO_START_DIR
ENV ZATO_START_DIR $ZATO_START_DIR
RUN rm -rf /opt/zato/env
COPY --from=zatobase:latest $ZATO_START_DIR $ZATO_START_DIR
COPY ./zato-component/build-zato-image.sh /opt/zato/env/build-zato-image.sh
RUN chown -R zato:zato /opt/zato/env
RUN ls -lahd $ZATO_START_DIR
WORKDIR /opt/zato
USER zato
RUN bash /opt/zato/env/build-zato-image.sh apply-hotfixes
ENTRYPOINT /opt/zato/current/bin/zato start $ZATO_START_DIR --fg
