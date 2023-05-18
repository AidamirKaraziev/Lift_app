"""empty message

Revision ID: 73224c4c985e
Revises: 65de75074d7c
Create Date: 2023-05-18 11:05:32.565744

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '73224c4c985e'
down_revision = '65de75074d7c'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_index('ix_firebasetoken_id', table_name='firebasetoken')
    op.drop_table('firebasetoken')
    op.drop_table('partner_competencies_of_project')
    op.drop_table('activity_spheres_of_project')
    op.drop_table('activity_spheres')
    op.drop_index('ix_device_id', table_name='device')
    op.drop_table('device')
    op.drop_table('partner_competencies')
    op.drop_table('area_of_responsibility')
    op.drop_table('projects')
    # op.drop_table('stage_of_implementation')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('area_of_responsibility',
    sa.Column('id', sa.INTEGER(), autoincrement=True, nullable=False),
    sa.Column('name', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.PrimaryKeyConstraint('id', name='area_of_responsibility_pkey'),
    sa.UniqueConstraint('name', name='area_of_responsibility_name_key')
    )
    op.create_table('projects',
    sa.Column('id', sa.INTEGER(), server_default=sa.text("nextval('projects_id_seq'::regclass)"), autoincrement=True, nullable=False),
    sa.Column('user_id', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('name', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('location_id', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('stages_of_implementation_id', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('budget', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('partners_share', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('about_the_project', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('site', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('photo_main', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('photo_1', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('photo_2', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('about_me', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('work_experience', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('my_strengths', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('opening_hours', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.ForeignKeyConstraint(['location_id'], ['locations.id'], name='projects_location_id_fkey', ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['stages_of_implementation_id'], ['stage_of_implementation.id'], name='projects_stages_of_implementation_id_fkey', ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], name='projects_user_id_fkey', ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name='projects_pkey'),
    sa.UniqueConstraint('name', name='projects_name_key'),
    sa.UniqueConstraint('user_id', 'name', name='projects_user_id_name_key'),
    postgresql_ignore_search_path=False
    )
    op.create_table('partner_competencies',
    sa.Column('id', sa.INTEGER(), server_default=sa.text("nextval('partner_competencies_id_seq'::regclass)"), autoincrement=True, nullable=False),
    sa.Column('name', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint('id', name='partner_competencies_pkey'),
    sa.UniqueConstraint('name', name='partner_competencies_name_key'),
    postgresql_ignore_search_path=False
    )
    op.create_table('device',
    sa.Column('id', sa.INTEGER(), server_default=sa.text("nextval('device_id_seq'::regclass)"), autoincrement=True, nullable=False),
    sa.Column('ip_address', postgresql.INET(), autoincrement=False, nullable=True),
    sa.Column('x_real_ip', postgresql.INET(), autoincrement=False, nullable=True),
    sa.Column('user_agent', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('accept_language', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('created', postgresql.TIMESTAMP(), autoincrement=False, nullable=True),
    sa.Column('detected_os', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('user_id', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['universal_users.id'], name='device_user_id_fkey', ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name='device_pkey'),
    postgresql_ignore_search_path=False
    )
    op.create_index('ix_device_id', 'device', ['id'], unique=False)
    op.create_table('activity_spheres',
    sa.Column('id', sa.INTEGER(), server_default=sa.text("nextval('activity_spheres_id_seq'::regclass)"), autoincrement=True, nullable=False),
    sa.Column('name', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('picture', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.PrimaryKeyConstraint('id', name='activity_spheres_pkey'),
    sa.UniqueConstraint('name', name='activity_spheres_name_key'),
    postgresql_ignore_search_path=False
    )
    op.create_table('stage_of_implementation',
    sa.Column('id', sa.INTEGER(), server_default=sa.text("nextval('stage_of_implementation_id_seq'::regclass)"), autoincrement=True, nullable=False),
    sa.Column('name', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.PrimaryKeyConstraint('id', name='stage_of_implementation_pkey'),
    sa.UniqueConstraint('name', name='stage_of_implementation_name_key'),
    postgresql_ignore_search_path=False
    )
    op.create_table('activity_spheres_of_project',
    sa.Column('id', sa.INTEGER(), autoincrement=True, nullable=False),
    sa.Column('project_id', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('activity_of_sphere_id', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['activity_of_sphere_id'], ['activity_spheres.id'], name='activity_spheres_of_project_activity_of_sphere_id_fkey', ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['project_id'], ['projects.id'], name='activity_spheres_of_project_project_id_fkey', ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name='activity_spheres_of_project_pkey'),
    sa.UniqueConstraint('project_id', 'activity_of_sphere_id', name='activity_spheres_of_project_project_id_activity_of_sphere_i_key')
    )
    op.create_table('partner_competencies_of_project',
    sa.Column('id', sa.INTEGER(), autoincrement=True, nullable=False),
    sa.Column('project_id', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('partner_competencies_id', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['partner_competencies_id'], ['partner_competencies.id'], name='partner_competencies_of_project_partner_competencies_id_fkey', ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['project_id'], ['projects.id'], name='partner_competencies_of_project_project_id_fkey', ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name='partner_competencies_of_project_pkey'),
    sa.UniqueConstraint('project_id', 'partner_competencies_id', name='partner_competencies_of_proje_project_id_partner_competenci_key')
    )
    op.create_table('firebasetoken',
    sa.Column('id', sa.INTEGER(), autoincrement=True, nullable=False),
    sa.Column('value', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('created', postgresql.TIMESTAMP(), autoincrement=False, nullable=True),
    sa.Column('device_id', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['device_id'], ['device.id'], name='firebasetoken_device_id_fkey'),
    sa.PrimaryKeyConstraint('id', name='firebasetoken_pkey')
    )
    op.create_index('ix_firebasetoken_id', 'firebasetoken', ['id'], unique=False)
    # ### end Alembic commands ###