FROM condaforge/miniforge3

ENV PYTHONUNBUFFERED 1

# Add user to avoid root access to attached dirs
ARG username=user
ARG groupname=user
ARG uid=1000
ARG gid=1000
RUN groupadd -f -g $gid $groupname \
    && useradd -u $uid -g $gid -s /bin/bash -d /home/$username $username \
    && mkdir /home/$username \
    && chown -R $username:$groupname /home/$username \
    && echo PATH=$PATH > /etc/environment \
    && chmod a+w /opt/conda

# Install essential Linux packages
RUN apt-get update \
    && apt-get install -y build-essential git curl wget unzip vim screen \
    && rm -rf /var/lib/apt/lists/*


# Install dependencies. Prioritize conda-forge channel (not restricted for for corporate users)
COPY environment.yaml /$username/conda_environment.yaml
RUN conda update -n base conda \
    && conda env update -n base -f /$username/conda_environment.yaml --prune

# Configure Jupyter individually (to not to include in the requirements)
COPY --chown=$username:$groupname .jupyter_password set_jupyter_password.py /home/$username/.jupyter/
RUN conda install jupyterlab \
    && conda clean --all --yes \
    && su $username -c "python /home/$username/.jupyter/set_jupyter_password.py $username"

USER $username
WORKDIR /code
EXPOSE 8888

CMD ["jupyter", "lab", "--no-browser"]
