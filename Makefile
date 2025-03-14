.PHONY: style quality

# make sure to test the local checkout in scripts and not the pre-installed one (don't use quotes!)
export PYTHONPATH = src

check_dirs := src tests

############### Installation
# 1) install uv
install-uv:
	curl -LsSf https://astral.sh/uv/install.sh | sh

# 2) set up virtual environment
venv:
	uv venv openr1 --python 3.11

# 3) activate virtual env
# # activate NB uses '.' instead of 'source' to work with dash/Codespaces as well)
# (. openr1/bin/activate)

# 4) install dev dependencies
install:	
	uv pip install --upgrade pip
	uv pip install vllm==0.7.2
	uv pip install setuptools
	uv pip install flash-attn --no-build-isolation
	GIT_LFS_SKIP_SMUDGE=1 uv pip install -e ".[dev]"

############### Linting

style:
	ruff format --line-length 119 --target-version py310 $(check_dirs) setup.py
	isort $(check_dirs) setup.py

quality:
	ruff check --line-length 119 --target-version py310 $(check_dirs) setup.py
	isort --check-only $(check_dirs) setup.py
	flake8 --max-line-length 119 $(check_dirs) setup.py

############### Test

test:
	pytest -sv --ignore=tests/slow/ tests/

slow_test:
	pytest -sv -vv tests/slow/

# Evaluation

evaluate:
	$(eval PARALLEL_ARGS := $(if $(PARALLEL),$(shell \
		if [ "$(PARALLEL)" = "data" ]; then \
			echo "data_parallel_size=$(NUM_GPUS)"; \
		elif [ "$(PARALLEL)" = "tensor" ]; then \
			echo "tensor_parallel_size=$(NUM_GPUS)"; \
		fi \
	),))
	$(if $(filter tensor,$(PARALLEL)),export VLLM_WORKER_MULTIPROC_METHOD=spawn &&,) \
	MODEL_ARGS="pretrained=$(MODEL),dtype=bfloat16,$(PARALLEL_ARGS),max_model_length=32768,gpu_memory_utilization=0.8,generation_parameters={max_new_tokens:32768,temperature:0.6,top_p:0.95}" && \
	if [ "$(TASK)" = "lcb" ]; then \
		lighteval vllm $$MODEL_ARGS "extended|lcb:codegeneration|0|0" \
			--use-chat-template \
			--output-dir data/evals/$(MODEL); \
	else \
		lighteval vllm $$MODEL_ARGS "custom|$(TASK)|0|0" \
			--custom-tasks src/open_r1/evaluate.py \
			--use-chat-template \
			--output-dir data/evals/$(MODEL); \
	fi
