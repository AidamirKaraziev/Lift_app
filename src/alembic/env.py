import sys
import os

from core.config import get_url

sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'src'))
from alembic import context
from sqlalchemy import engine_from_config, pool
from logging.config import fileConfig
from core.db.base_class import Base

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

fileConfig(config.config_file_name)
target_metadata = Base.metadata


def run_migrations_offline():
    url = get_url()
    context.configure(
        url=url, target_metadata=target_metadata, literal_binds=True, compare_type=True
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    configuration = config.get_section(config.config_ini_section)
    configuration["sqlalchemy.url"] = get_url()
    connectable = engine_from_config(
        configuration, prefix="sqlalchemy.", poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata, compare_type=True
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
