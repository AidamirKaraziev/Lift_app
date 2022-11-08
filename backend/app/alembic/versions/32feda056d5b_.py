"""empty message

Revision ID: 32feda056d5b
Revises: 4627b6d9051a
Create Date: 2022-08-24 19:25:29.796940

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '32feda056d5b'
down_revision = '4627b6d9051a'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_unique_constraint(None, 'test_users', ['email'])
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint(None, 'test_users', type_='unique')
    # ### end Alembic commands ###
