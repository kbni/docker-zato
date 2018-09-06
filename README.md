
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

## Update

I have decided against running this inside Docker Swarm, instead I have opted to run multiple Zato clusters on indivdual systems. For me, this achieves my goal of having Zato be easier to deploy within our organisation but for scaling this is not particularly useful at all.

Also, I have now moved everything into a `docker` directory because this is a direct copy of what I keep in my primary zato repository; below that primary repository is a handful of other tools used for management of zato and of course services themselves.

## Usage

1. Clone the repository
    ```
    git clone https://github.com/kbni/docker-zato.git
    cd docker-zato
    ```

2. Run `compose.sh` which will do a whole bunch of stuff for you
    ```
    ./docker/compose.sh
    ```

3. Build containers which will actually be used in the container
   ```
   ./docker/compose.sh build
   ```

4. Start them up!
   ```
   ./docker/compose.sh up
   ```

5. Navigate to the Zato web interface at http://localhost:8183/

## Credentials

_Credentials for various components, including the Zato web admin login can be retrieved from_ `secrets/env_file`_._

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


