"""empty message

Revision ID: a067234b18ec
Revises: 451f6c309331
Create Date: 2023-01-25 11:02:29.229195

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'a067234b18ec'
down_revision = '451f6c309331'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('acts_fact_of_mechanic',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('act_fact_id', sa.Integer(), nullable=False),
    sa.Column('mechanic_id', sa.Integer(), nullable=False),
    sa.ForeignKeyConstraint(['act_fact_id'], ['acts_fact.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['mechanic_id'], ['universal_users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('act_fact_id', 'mechanic_id')
    )
    op.drop_table('acts_fact_of_mechanic_id')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('acts_fact_of_mechanic_id',
    sa.Column('id', sa.INTEGER(), autoincrement=True, nullable=False),
    sa.Column('act_fact_id', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('mechanic_id', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['act_fact_id'], ['acts_fact.id'], name='acts_fact_of_mechanic_id_act_fact_id_fkey', ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['mechanic_id'], ['universal_users.id'], name='acts_fact_of_mechanic_id_mechanic_id_fkey', ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name='acts_fact_of_mechanic_id_pkey'),
    sa.UniqueConstraint('act_fact_id', 'mechanic_id', name='acts_fact_of_mechanic_id_act_fact_id_mechanic_id_key')
    )
    op.drop_table('acts_fact_of_mechanic')
    # ### end Alembic commands ###