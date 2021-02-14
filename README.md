# sensum

Sensum make sentimental analysis possible thanks to the huggingface's transformers library https://github.com/huggingface/transformers

## why this name?

`sentiment` in Latin is `sensum`. I am french, I live in a root world, `Latin` is the root language of `French`... 

## goal

The aim of sensum is to make sentimental analysis possible via an http api. Deployable in a docker-ish environment.

## dependencies
Lots of python stuff:
- `python3` as python runtime
- `virtualenv` for the development environment
- `huggingface` library
- `flask` to make writting http api easier
- `gunicorn` as an http server


## api documentation
### Analysis
----
  Returns json data about the sentimental analysis. The response array will be the same length as the sentences one; 

* **URL**

  /analysis/

* **Method:**

  `POST`
  

* **Data Params**

  ```json
  {"sentences":["Is linux the best operating system?", "SRE is treating infrastructure as a software problem"]}
  ```

* **Success Response:**

  * **Code:** 200 <br />
    **Content:** `[{"label":"POSITIVE","score":0.9438539743423462},{"label":"NEGATIVE","score":0.9991174936294556}]`
 
* **Error Response:**

  * **Code:** 400 BAD REQUEST <br />
    **Content:** `Malformed json`

* **Sample Call:**

  ```bash
  curl -X POST -H 'Content-Type: application/json' \
  http://localhost:8081/analysis \
  -d '{"sentences":["Is linux the best operating system?", "SRE is treating infrastructure as a software problem"]}'
  ```

## how to run?

### locally
A script called `configure.sh` configures your development environment by creating a `virtualenv`
and installing the dependencies thanks to the `requirements.txt` file.

### development mode
You can run via the `api.py` file:
```bash
$ python api.py
 * Serving Flask app "api" (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: off
 * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
```

Or via `docker`:
```bash
$ docker build . -t sensum
...
$ docker run -p 8090:8080 sensum
```

### gcp and app engine
This api will not go to production. It is a proof of knowledge I would say. 

First of all, using `kubernetes` would have been overkill. 
1. Because it is an experimental api
2. Because the workload is very low, the need of scalability too.
3. If this would be a production-ready api I would reconsider the preceding statements.

**Alternative:**

I could have use `terraform` to build the infrastructure part. 
Use `packer` to create instance image with the necessary dependencies, with a startup script to
retrieve the latest version of the api... Well there is a lot of solutions to this problem :)

**!!!! I REPEAT THIS IS NOT A PRODUCTION-READY API !!!!**


### why app engine?
Because we have `Dockerfile`, a faas solution make things easier and faster to deploy.
Just adding a `app.yaml` file to declare how to run it with `app engine` and we are good to go:

```yaml
runtime: custom
env: flex
```
Then, deploy the api:
```bash
gcloud app deploy
```

## assumption, tests and results

### assumption
My assumption is that this api is cpu-bounded. As we don't have any GPUs, the horsepower will be given by the CPUs.

The scalability problem will be somewhat easy to resolve. As long as we have a lot of money, 
and because this api is stateless, adding more horsepower (vertically or horizontally) will do the trick. The scalability threshold will be a cpu one.

### we all love dragon ball z
I used [vegeta](https://github.com/tsenart/vegeta) to test/flood the api.

There is a file called `vegeta-target.list` which describe how to target the api. With the corresponding load samples.

**If you change the port of the api, don't forget to do it also in this file.**

```text
POST http://localhost:8080/analysis
Content-Type: application/json
@load-sample.json
POST http://localhost:8080/analysis
Content-Type: application/json
@load-sample-1.json
```

Let's attack the api (10 req/sec):

`vegeta attack -rate=10/s -targets=vegeta-target.list`

Thanks to `cadvisor` on my own vm I could monitor how the container handle the load:

CPU:
![cpu](cpu.png?raw=true "CPU")

Memory:
![memory](memory.png?raw=true "MEMORY")

As I've expected, this api is cpu-bounded. The cpu load increase as I send more traffic. Whereas the memory stay constant.
My assumption on why we are using at least 600MB, is that we load the json models file into memory.


## things to improve
During my test, I saw a lot of network traffic at the start of the app which corresponds to the models download. 
I didn't find on the documentation how to cache the model, except that we have to contact the [huggingface's team](https://huggingface.co/transformers/installation.html#note-on-model-downloads-continuous-integration-or-large-scale-deployments).

I had to downgrade the `huggingface` library version because of a `rust` borrow error [issue](https://github.com/huggingface/tokenizers/issues/537). I think is due to the number of parallel requests I sent.
So sticking to the latest version may help to improve the performance.

