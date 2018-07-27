# docker-zato

A `docker-compose.yml` file for building out a [Zato](https://github.com/zatosource/zato) cluster. Created because:

* I would like to deploy Zato using Docker within my current organisation
* [Other people seemed interested in achieving the same](https://github.com/zatosource/zato/issues/515)
 
## Disclaimer

- This has not been tested with any real use
- This probably violates many best-practices of Docker, docker-compose
- This is day 2 of me getting to know Docker, see the previous point!
- This will generate image(s) containing potentially privileged information (`zatobase:latest`).
  Be careful where this image ends up. It must not fall into the wrong hands!

## Usage (non-cluster)

1. Clone the repository
    ```
    git clone https://github.com/kbni/docker-zato.git
    cd docker-zato
    ```
2. Run `compose.sh` which will do a whole bunch of stuff for you
    ```
    ./compose.sh
    ```
3. Build the `zatobase:latest` image
    ```
    docker build . -t zatobase:latest
    ```
4. Build containers which will actually be used in the container
   ```
   ./compose.sh build
   ```
5. Start them up!
   ```
   ./compose.sh up
   ```
6. Navigate to the Zato web interface at http://localhost:8183/

## Usage (Docker Swarm)

Not very clean, but it worked!

1. Clone the repository
    ```
    git clone https://github.com/kbni/docker-zato.git
    cd docker-zato
    ```

2. Run `compose.sh` which will do a whole bunch of stuff for you
    ```
    sudo ./compose.sh
    ```
    
3. Modify `docker-compose.yml` so that each service has the following keys:
   ```
      image: 172.16.128.70:5000/zato-odb
      deploy:
        placement:
          constraints:
            - node.role != manager
   ```

4. Run `docker-compose build` which should build out the images
    ```
    sudo docker-compose build
    ```
    
5. Run `docker-compose push` which should send the images to your registry
    ```
    sudo docker-compose push
    ```
6. Paste your `docker-compose.yml` file into the Stack deployment section of Portainer

## Credentials

_Credentials for various components, including the Zato web admin login can be retrieved from_ `.secrets/env_file`_._

## Challenges

If you are more experienced with the internals of Zato and/or Docker, I would greatly appreciate it if you would provide
some feedback on how I approached these challenges. I am certain this could be done much cleaner!

### Build-order

It was super difficult to get all the containers to work properly when their zato components were constructed at run-time,
additionally it seemed like too much effort to properly maintain the state of zato components, so I opted to simply
build them in a base image file, and then use that base image to generate images which are actually supposed to run!

### Working database required for build

Similar to above. It's hard to spin up Zato components, and very difficult if you do not have access to a working
database for the ODB. To get around this, I simply installed PostgreSQL on the `zatobase` image. This PostgreSQL
instance is not used on other images (only started by ENTRYPOINT).

### HAProxy 1.6 requires resolvable names

Unfortunately HA Proxy needs to run after the zato-server_xx_ nodes have started so HA Proxy can resolve the addresses
of the various Zato Servers. It seems like if HAProxy 1.7 was used this would not be a problem, but as a workaround
I simply opted to have the `zato-load-balancer` node depend on the various `zato-serverXX` nodes. 

At least in my environment, it seems that when these containers are restarted they retained the same IP address. I guess
time will tell. I also considered adding a separate nginx proxy "just in case", but since haproxy is working I won't just yet.

### `docker-compose` is not super helpful with regard to "complicated" contexts

It seems `docker-compose` has a thing called 'contexts' which makes sharing files among multiple
Dockerfiles from a central location difficult (unless you have somewhere to host them). This is the
original reason I created `compose.sh`, which basically sets `docker-compose` up with a context directory.
_It also does other things, like generate a secrets file, and certificates..._

## Thanks

I'd just like to take a moment and say that Docker is awesome, thank you Docker people!
Also, give it up for Dariusz and the rest of the Zato team!

