import json
import logging

import sqlalchemy as sa
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker
from sseclient import SSEClient as EventSource

from hear import settings

log = logging.getLogger('hear')

# globals
Base = declarative_base()
DBSession = scoped_session(sessionmaker())
engine = None


class Events(Base):
    __tablename__ = settings.EVENTS
    __table_args__ = {"schema": settings.SCHEMA}
    pk = sa.Column(sa.BigInteger, primary_key=True)
    event = sa.Column(sa.JSON)


def init_sqlalchemy(db_url=settings.DB_URL):
    global engine
    engine = sa.create_engine(db_url, echo=False)
    DBSession.remove()
    DBSession.configure(bind=engine, autoflush=False, expire_on_commit=False)


def process_stream(event_type, frac=1.0, db_url=settings.DB_URL):
    """Listen for event changes and propogate to DB.
    """

    # setup
    init_sqlalchemy(db_url=db_url)
    i = 0
    total = 0
    log.warn("Listening for new EventSource data.  Please wait ...")
    try:
        for event in EventSource(settings.SSE_URL):
            if event.event == event_type:
                try:
                    record = json.loads(event.data)
                    event = Events(event=record)
                    DBSession.add(event)
                    i += 1
                    # batch inserts for performance
                    if i % 100 == 0:
                            DBSession.flush()
                            DBSession.commit()
                            total += i
                            i = 0
                            log.info("Heard and inserted {} SSEvents total.".format(total))

                except ValueError:
                    pass

    except Exception:
        raise
    finally:
        DBSession.flush()
        DBSession.commit()
