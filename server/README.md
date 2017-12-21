### GListen

Clutter take-home programming assignment.

---
#### Install Instructions

##### Server Container
This will configure and run a Docker container to host the PostgreSQL instance which will serve as the datastore for this assignment.

1. Checkout from Github.
   * `git clone http://www.github.com/predicatelogic/glisten`
2. Build Docker container and run it.
   * `./run_docker.sh -s`
      * This will build the docker container if it doesn't already exist.
   
##### Getter
This code retreives the stream and stores it in the Dockerized PG instance.

In a new terminal:
1. Run "getter".
   * `./run_docker.sh -g`


##### Listener
This code listens for event changes in the local Dockerized PG instance and will spit the change record(s) out as JSON.

In a new terminal:
1. Run "listener".
   * `./run_docker.sh -l`

##### Reporter (optional)
This code listens for changes but materializes the information as a web-based report.

In a new terminal:
1. Start web reporting interface.
   * `./run_docker.sh -r`


