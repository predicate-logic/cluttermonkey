### Clutter Monkey

Clutter take-home programming assignment.  

The assigment has three infrastructural components:

   * PostgreSQL database for the data store.
   * Python ETL to retreive and ingest the Wiki event stream.
   * A browser based query/visualization tool (SQLPad) with some example queries and prebuilt visualizations for the "real-time" data.

I've opted to install all deliverables into a single Docker container to make the experience easy to reproduce locally for testing.  Please follow the instructions below to retrieve the project from my GitHub repo and then run the required command to build the environment.  

Please note building the Docker container for this project can take a while.  Once built though re-running the start command will restart the server in a clean state and start the collection process anew.  Once started you can go to the browser endpoint to run the queries and visualization against the data as it is collected in real-time. 

---
#### Install Instructions

This will configure and run a Docker container to host the PostgreSQL instance which will serve as the datastore for this assignment as well as the visualization utility.

1. Checkout from Github.
   * `git clone http://www.github.com/predicate-logic/cluttermonkey`
2. Build Docker container and run it.
   * `cd cluttermonkey && ./run.sh -r`
      * Initial container build can take 10+ minutes and will print instructions once the container has been built and is ready for use.
      * Once container builds and starts itself it will start collecting events.
3. You can stop the container by typing `Ctrl-C` in the same terminal window that you started the run from. 

NOTE: all passwords for all services within the container should be the string literal "`password`".

#### Post-Installation

After the run command has built the Docker container and started the tool running the following has happened:

   * An Ubuntu 16.04 (LTS) instance is running as a container.
   * Within the container an PostgreSQL 10.1 instance has been configured and is running as the primary datastore for this excercise.
      * Example `psql` connect command: `psql -U postgres clutter`
      * Schema created and configured with script in: `$HOME/script/create.sql`
   * A Python script (`hear.cli`) has been started inside the container and is listenting for SSEvents and is inserting them in the datastore.
   * A SQLPad web-based visualization server has been started at port 3000 (http://localhost:3000).  
      * Username: `admin@cluttermonkey.com`
      * Password: `password`

===

#### Deliverables
##### Step #1 (Pipeline Sketch)

```
                 +---------------------------------------------------------------------------+
                 |                                                                           |
                 +------------------------------------------------+                          |
                 ||                                               |                          |
+-------------+  ||   +--------------+       +----------------+   |             +--------+   |
|             |  ||   |              |       |                |   |             |        |   |
|  SSEvents   +------>+  Python      +------^+  Datastore (PG)+--5432:54321---->+  PSQL  |   |
|             |  ||   |              |       |                |   |             |        |   |
+-------------+  ||   +--------------+       +-------+--------+   |             +--------+   |
                 ||                                  |            |                          |
                 ||                          +-------+-------+    |             +--------+   |
                 ||                          |               |    |             |        |   |
                 ||                          |  SQLPad (Viz) +^--3000:3000----->+Browser |   |
                 ||                          |               |    |             |        |   |
                 ||                          +---------------+    |             +--------+   |
                 ||                                               |                          |
                 ||                                               |                          |
                 ||  Container                                    |                          |
                 +------------------------------------------------+                          |
                 |                                                                           |
                 |   Host                                                                    |
                 +---------------------------------------------------------------------------+
```
Basic plan is to use a Python script to poll the SSEvent stream and push these events into a Datastore.

##### Step 2e (Schema Design)
Datastore choice is PostgreSQL 10.1 due to it's native JSONB datatype that compresses and stores JSON easily (`clutter_raw.events`) and the flexibility to create views on the JSON data to materialize the columns into a normalized table structure (`clutter_stage.v_events`) in a performant manner.

Schema is created from script in: `$HOME/script/create.sql` for full details.

##### Step 3.1 (Real-time Updating)
See diagram from **Step 1**.  Python code (`$HOME/hear/cli.py`) listens continously for changes in the SSEvent stream and bulk inserts them in batches of 100 into the PostgreSQL data store.  

The `hear.cli` Python script is fully CLI compliant and has built in help.  You can see it's help file by running `cd $HOME/hear && python -m hear.cli --help` from a BASH session inside the Docker container.  The script only has a single command `stream`.

Example Usage (from host):

   1. On the host: `cd cluttermonkey`
   2. Start a BASH shell inside running Docker container: `./run.sh -b`
   3. Move into `hear` source directory: `cd /hear`
   4. Run script to get help: `python -m hear.cli stream --help`

```
postgres@cluttermonkey_hear:/hear$ python -m hear.cli stream --help
Usage: cli.py stream [OPTIONS]

  Retrieve stream of events.

Options:
  -q, --quiet        Only show errors or output data to terminal.
  -v, --verbose      Turn on verbose logging.
  --event-type TEXT  Filter event types.  Defaults to 'message' type.
  --frac FLOAT       Sample data fraction.  Defaults to 1.0
  --db_url TEXT      Override SQLAlchemy connection URL
  --help             Show this message and exit.

```

##### Step 3.2 (Real-time Querying)
Query functionality is provided by the integrated SQLPad web-based query and visualization application.  Steps to acces it can be found below:

1. From your host open a web-browser and navigate to: `http://localhost:3000`.
2. Login using: `admin@cluttermonkey.com` / `password`
3. There are variety of queries that I have built in the tool that will return either the data set or a visualization ("chart").  

##### Step 4.e (Code-as-archive)
The GitHub repository at `https://github.com/predicate-logic/cluttermonkey` should satisfy this requirement.

##### Step 5 (Sample Reports)
See `Step 3.2` for instructions to use SQLPad for ad-hoc querying and visualization capability against the live datastore.

===

#### Questions
Per the instructions here are my answers to the questions:

   * **Q**: If you received this specification what questions would you ask that would influence your pipeline and data store decisions?
      * **A**: Initially I would probably focus on the "3 V's" for this stream of data: Volume, Velocity, and Variety.  The Volume and Velocity of data is actually pretty high with potentailly thousands of change record events recorded per minute.  On the Variety side the data is JSON based with a flexible schema.  

      I originally created the schema for this application by normalizing all of the JSON fields for an hour of collection but even then there were still some fields that only showed up in 1-in-100,000 records that if they weren't accounted for would either break the current pipline or if they were discarded would mean lost data.  Because of this I opted to use the JSON data type for PostgreSQL so that the original change record could be recorded in it's entirety.  This also has the effect of simplifying the collection ETL making it relatively performant in comparision to to the Volume of records it needed to process.  
      
      In the case where Velocity or Volume or records might be extreme I additionally added a sampling parameter to the ETL to only select `N` per 100 records, as well the ability to filter by message type.

      
   * **Q**: What assumptions are you making about the data, use cases, or reports needed?
      * **A**: The largest assumption the current codebase makes is that all data flows into a single, un-partitioned table which in production wouldn't be a good choice.  If this were a production ready pipeline I would partition the table using PG 10.1's native partioning and additionally include `pg_partman` for automatic partition managment.  

      I additionally make the assumption that most queries against the `events` data will be range-bounded by date predicate (e.g. query X for the last 15-minutes, last 24-hours, etc).  I have created BRIN partition indexes on the `event_ts` timestamp field to speed up these types of queries.  BRIN indexes are particularly well suited for this type of access pattern for OLAP servers where the data is naturally ordered.

      
   * **Q**: Why did you choose the data store that you did?
      * **A**: My familiarity with PostgreSQL and I know it is used at Clutter making it easier to reason about my solution by whomever would evaluate my solution.  I could have also used any other relational (MySQL/Oracle/Redshift/Snowflake/CitusDB/PipelineDB) or non-relational DB (MongoDB/DyanamoDB).

   * **Q**: What are some other options you could have used, and why what advantages or disadvantages would they have?
      * **A**: Redshift, Snowflake, or CitusDB would be an interesting option as they are columnar databases that wouldn't require the additional maintenance and implementation complexity of partitioning and partition management in PostgreSQL.

      MongoDB could be a decent choice due to it's simplicity of implementing JSON storage as it is a JSON native document database.  I personally think for the volume of data though it's performance would be sub-standard.  Additionally many tools don't support MongoDB for easy querying of data due to it's non-standard query language.
      
      DynamoDB would be interesting from a scalability standpoint.  Overall you have to decide on your query semantics in advance though as you can only have a limited number of indexes and any ad-hoc queries could consume lots of processing power driving up costs for this DB option.

   * **Q**: How does the volume or speed of the stream affect your design?
      * **A**: Please see my answer to the first Question.  It was a critical factor on the decision of how to write the ingestion tool and for some of the field and index choices within the resulting schema.

      
   * **Q**: How did the need to report on the data in a streaming manner affect your design? 
      * **A**: I made a simple design decision on the streaming aspect of the implementation and chose to use an "off-the-shelf" tool (SQLPad) to provide the ability to query the data in real time.  Although not a streaming enabled query tool such as Slide (PipelineDB) due to efficient indexing and windowing of the data it is possible to query the data in "real-time" by simply re-running the query or visualization in the SQLPad browser window.

      To be truely streaming with PG as the data store I would need to implment an asyncronous `NOTIFY` listener in `psycopg2`.  This would also require implmentation of an INSERT trigger in the database.  This was not done but could be completed with a couple of hours of work.

      
   * **Q**: What challenges did you encounter in this exercise?
      * **A**: Not many.  My biggest issue was getting NodeJS to install cleanly in the Dockerized environment.  I had a lot of fun working on this assignment and playing with SQLPad, which I hadn't done previously.  Pretty slick and easy to implement visualization tool which I may use in other projects.

===

### Other Topics

A few other notes:
   
   * You can stop the Docker container with `./run.sh -s` or by typing `Ctrl-C` from the terminal window where you first started the `run.sh -r` command.
      * This will stop the running Docker container and all of it's internal processes and reset the state of the container.
  
  * The Docker container is reset on each start so any data collected in a previous run will be missing on a subsequent start of the container.  Because of this the most recent edits queries will need to collect new data for a few minutes if you re-run the container.
  
  * While the container is running you can run `./run.sh -b` if you want to `exec` a BASH shell to look around.

  * You can run `./run.sh -?` to get help on any available commands.

  * `password` is the password to all processes in the exercise.  `admin@clutermonkey.com` is the username for SQLPad. 







