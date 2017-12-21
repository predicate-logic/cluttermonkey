import json
import logging

import sqlalchemy as sa
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker
from sseclient import SSEClient as EventSource

from get import settings

logging.basicConfig()
log = logging.getLogger()

# globals
Base = declarative_base()
DBSession = scoped_session(sessionmaker())
engine = None


class Events(Base):
    __tablename__ = settings.EVENTS
    __table_args__ = {"schema": settings.SCHEMA}
    pk = sa.Column(sa.BigInteger, primary_key=True)
    event = sa.Column(sa.JSON)


def init_sqlalchemy(dbname=settings.DB_URL):
    global engine
    engine = sa.create_engine(dbname, echo=False)
    DBSession.remove()
    DBSession.configure(bind=engine, autoflush=False, expire_on_commit=False)


def process_stream(event_type, frac=1.0):
    """Listen for event changes and propogate to DB.
    """

    # setup
    init_sqlalchemy()
    i = 0
    total = 0
    print("Listening for new EventSource data.  Please wait ...")
    try:
        for event in EventSource(settings.SSE_URL):
            if event.event == event_type:
                try:
                    record = json.loads(event.data)
                    event = Events(event=record)
                    DBSession.add(event)
                    i += 1
                    if i % 100 == 0:
                            DBSession.flush()
                            DBSession.commit()
                            total += i
                            i = 0
                            print("Inserted total: {}".format(total))

                except ValueError:
                    pass

    except Exception:
        raise
    finally:
        DBSession.flush()
        DBSession.commit()
