### Clutter Monkey

Clutter take-home programming assignment.  

The assigment has three infrastructural components:

   * PostgreSQL database for the data store.
   * Python ETL to retreive and ingest the Wiki event stream.
   * A browser based query/visualization tool (SQLPad) with some example queries and prebuilt visualizations for the "real-time" data.

I've opted to install all deliverables into a single Docker container to make the experience easy to reproduce locally for testing.  Please follow the instructions below to retrieve the project from my GitHub repo and then run the required command to build the environment.  

Please note building the Docker container for this project can take a while.  Once built though re-running the start command will re-start the server in a clean state and start the collection process anew.  Once started you can go to the browser endpoint to run the queries and visualization against the data as it is collected in real-time. 

---
#### Install Instructions

This will configure and run a Docker container to host the PostgreSQL instance which will serve as the datastore for this assignment as well as the visualization utility.

1. Checkout from Github.
   * `git clone http://www.github.com/predicatelogic/cluttermonkey`
2. Build Docker container and run it.
   * `cd cluttermonkey && ./run.sh -r`
      * Initial container build can take 10+ minutes and will print instructions once the container has been built and is ready for use. 

NOTE: all passwords for all services within the container should be the string literal "`password`".

#### Post-Installation

After the run command has built the Docker container and started the tool running the following has happened:

   * An Ubuntu 16.04 (LTS) instance is running as a container.
   * Within the container an PostgreSQL 10.1 instance has been configured and is running as the primary datastore for this excercise.
      * Example `psql` connect command: `psql -U postgres clutter`
      * Schema created with script in: `$HOME/hear/script/create.sql`
   * A Python script (here.cli) has been started inside the container and is listenting for SSEvents and is inserting them in the datastore.
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

Schema is created from script in: `$HOME/hear/script/create.sql` for full details.

##### Step 3.1 (Real-time Updating)
See diagram from **Step 1**.  Python code (`$HOME/hear/hear/cli.py`) listens continously for changes in the SSEvent stream and bulk inserts them in batches of 100 into the PostgreSQL data store.  

The `hear.cli` Python script is fully CLI compliant and has built in help.  You can see it's help file by running `cd $HOME/hear && python -m hear.cli --help`.  The script only has a single command `stream`.

Example Usage (from host):

   1. `cd cluttermonkey`
   2. Start a BASH shell inside running Docker container: `./hear/run.sh -b`
   3. Move into `here` source directory: `cd /hear`
   4. Run script: `python -m here.cli stream --help`

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

      I additionally make the assumption that most queries against the `events` data will be range-bounded by date (e.g. last 15-minutes, last 24-hours, etc).  I have created BRIN partition indexes for the table though as they help prevent full-table scans and are particularly effective in data warehous scenarios where the data is naturally ordered.

      
   * **Q**: Why did you choose the data store that you did?
      * **A**: My familiarity with PostgreSQL and I know it is used at Clutter making it easier to reason about my solution by whomever would evaluate my solution.  I could have also used any other relational (MySQL/Oracle/Redshift/Snowflake/CitusDB/PipelineDB) or non-relational DB (MongoDB/DyanamoDB).

   * **Q**: What are some other options you could have used, and why what advantages or disadvantages would they have?
      * **A**: Redshift, Snowflake, or CitusDB would be another interesting option as they are columnar databases that wouldn't require the additional maintenance and implementation complexity of partitioning and partition management in PostgreSQL.

      MongoDB would be interesting due to it's simplicity of implementing JSON storage as it is a JSON native document database.  I personally think for the volume of data though it's performance would be sub-standard.
      
      DynamoDB would be interesting from a scalability standpoint.  Overall you have to decide on your query semantics in advance though as you can only have a limited number of indexes and any ad-hoc queries could consume lots of processing power driving up costs on this DB option.

   * **Q**: How does the volume or speed of the stream affect your design?
      * **A**: Please see my answer to the first Question.  It was a critical factor on the decision of how to write the ingestion tool and for some of the field and index choices within the resulting schema.

      
   * **Q**: How did the need to report on the data in a streaming manner affect your design? 
      * **A**: I made a simple design decision on the streaming aspect of the implementation and chose to use an "off-the-shelf" tool (SQLPad) to provide the ability to query the data in real time.  Although not a streaming enabled query tool such as Slide (PipelineDB) due to efficient indexing and windowing of the data it is possible to query the data in "real-time" by simply re-running the query or visualization in the SQLPad browser window.

      To be truely streaming with PG as the data store I would need to implment an asyncronous `NOTIFY` listener in `psycopg2`.  This would also require implmentation of an INSERT trigger in the database.  This was not done but could be relatively easily.

      
   * **Q**: What challenges did you encounter in this exercise?
      * **A**: Not many.  Had a lot of fun building this tool and playing with SQLPad.

===

### Other Topics

A few other notes:
   
   * You can stop the Docker container with `./hear/run.sh -s`.
      * This will stop the running Docker container and all of it's internal processes.
  
  * The Docker container is reset on each start so any data collected in a previous run will be missing on a subsequent start of the container.  Because of this the most recent edits queries will need to collect new data for a few minutes.
  
  * You can run `./run.sh -b` if you want to `exec` a BASH shell into the running container to look around.

  * You can run `./run.sh -?` to get help on any available commands.

  * `password` is the password to all processes in the exercise.  `admin@clutermonkey.com` is the username for SQLPad. 







