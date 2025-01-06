This section contains the instruction for setup from [DataExpert-io/data-engineer-handbook](https://github.com/DataExpert-io/data-engineer-handbook/tree/main/bootcamp). To run Postgres and PGAdmin I'm using the Docker option instead of local machine setup.

Literally copy pasted the instructions below:

 
:wrench: **Tech Stack**

- Git
- Postgres
- PSQL CLI
- Database management environment (DataGrip, DBeaver, VS Code with extensions, etc.)
- Docker, Docker Compose, and Docker Desktop

:pencil: **TL;DR**

1. [Clone the repository](https://github.com/DataExpert-io/data-engineer-handbook/edit/main/bootcamp/materials/1-dimensional-data-modeling/README.md).
2. [Start Postgres instance](https://github.com/DataExpert-io/data-engineer-handbook/edit/main/bootcamp/materials/1-dimensional-data-modeling/README.md#2%EF%B8%8F%E2%83%A3run-postgres).
3. [Connect to Postgres](https://github.com/DataExpert-io/data-engineer-handbook/edit/main/bootcamp/materials/1-dimensional-data-modeling/README.md#threeconnect-to-postgres-in-database-client) using your preferred database management tool.

For detailed instructions and more information, please refer to the step-by-step instructions below.

## 1️⃣ **Clone the repository**

- Clone the repo using the SSH link. This will create a new folder in the current directory on your local machine.
    
    ```bash
    git clone git@github.com:DataExpert-io/data-engineer-handbook.git
    ```
    
    > ℹ️ To securely interact with GitHub repositories, it is recommended to use SSH keys. Follow the instructions provided **[here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)** to set up SSH keys on GitHub.
    > 

- Navigate into the cloned repo using the command line:
    
    ```bash
    cd data-engineer-handbook/bootcamp/materials/1-dimensional-data-modeling
    ```

## 2️⃣ **Run Postgres**

There are two methods to get Postgres running locally.

### 💻 **Option 1: Run on local machine**

1. Install Postgres
    - For Mac: Follow this **[tutorial](https://daily-dev-tips.com/posts/installing-postgresql-on-a-mac-with-homebrew/)** (Homebrew is really nice for installing on Mac)
    - For Windows: Follow this **[tutorial](https://www.sqlshack.com/how-to-install-postgresql-on-windows/)**
2. Run this command after replacing **`<computer-username>`** with your computer's username:

    ```bash
    pg_restore -U <computer-username> -d postgres data.dump
    ```

    If you have any issue, the syntax is `pg_restore -U [username] -d [database_name] -h [host] -p [port] [backup_file]`
    
3. Set up DataGrip, DBeaver, or your VS Code extension to point at your locally running Postgres instance.
4. Have fun querying!

### 🐳 **Option 2: Run Postgres and PGAdmin in Docker**

- Install Docker Desktop from **[here](https://www.docker.com/products/docker-desktop/)**.
- Copy **`example.env`** to **`.env`**:
    
    ```bash
    cp example.env .env
    ```

- Start the Docker Compose container:
    - on Windows:
        
        ```bash
        docker compose up -d
        ```
        
- A folder named **`postgres-data`** will be created in the root of the repo. The data backing your Postgres instance will be saved here.
- You can check that your Docker Compose stack is running by either:
    - Going into Docker Desktop: you should see an entry there with a drop-down for each of the containers running in your Docker Compose stack.
    - Running **`docker ps -a`** and looking for the containers with the name **`postgres`**.
- If you navigate to **`http://localhost:5050`** you will be able to see the PGAdmin instance up and running and should be able to connect to the following server as details shown:
    
    <img src=".attachments/pgadmin-server.png" style="width:500px;"/> 


- When you're finished with your Postgres instance(required in week 1 & 2 & 4), you can stop the Docker Compose containers with:
    
    ```bash
    docker compose stop
    ```

## :three: **Connect to Postgres in Local Database Client**

- Some options for interacting with your Postgres instance:
    - DataGrip - JetBrains; 30-day free trial or paid version
    - VSCode built-in extension (there are a few of these).
    - PGAdmin.
    - Postbird.
    - Dbeaver
- Using your client of choice, follow the instructions to establish a new PostgreSQL connection.
    - The default username is **`postgres`** and corresponds to **`$POSTGRES_USER`** in your **`.env`**.
    - The default password is **`postgres`** and corresponds to **`$POSTGRES_PASSWORD`** in your **`.env`**.
    - The default database is **`postgres`** and corresponds to **`$POSTGRES_DB`** in your **`.env`**.
    - The default host is **`localhost`** or **`0.0.0.0`.** This is the IP address of the Docker container running the PostgreSQL instance.
    - The default port for Postgres is **`5432` .** This corresponds to the **`$CONTAINER_PORT`** variable in the **`.env`** file.
    
    &rarr; :bulb: You can edit these values by modifying the corresponding values in **`.env`**.
    
- If the test connection is successful, click "Finish" or "Save" to save the connection. You should now be able to use the database client to manage your PostgreSQL database locally.


## **🚨 Tables not loading!? 🚨**

- When the tables didn't come with the loaded data, I followed these steps:

1. Find the container id by running `docker ps` - under CONTAINER ID in the terminal
2. Go inside the container by executing `docker exec -it <container_name_or_id> bash`
3. Run `pg_restore -U $POSTGRES_USER -d $POSTGRES_DB /docker-entrypoint-initdb.d/data.dump` 
$POSTGRES_USER = postgres
$POSTGRES_DB = postgres

---