from sqlite3 import Date, Timestamp
from typing import Optional
from pydantic import BaseModel, Field

from app.schemas.object import ObjectGet
from app.schemas.fault_category import FaultCategoryGet
from app.schemas.universal_user import UniversalUserGet
from app.schemas.reason_fault import ReasonFaultGet
from app.schemas.status import StatusGet
from app.schemas.order_photo import OrderPhotoGet


class OrderBase(BaseModel):
    id: int
    object_id: Optional[int]
    creator_id: int
    fault_category_id: Optional[int]
    task_text: Optional[str]

    executor_id: int
    commentary: Optional[str]
    reason_fault_id: Optional[int]

    created_at: Optional[Timestamp]
    accepted_at: Optional[Timestamp]
    in_progress_at: Optional[Timestamp]
    done_at: Optional[Timestamp]

    status_id: Optional[int]
    is_viewed: Optional[bool]


class OrderCreate(BaseModel):
    # id: int
    object_id: Optional[int]
    creator_id: Optional[int]
    fault_category_id: Optional[int]
    task_text: Optional[str]

    executor_id: int
    # commentary: Optional[str]
    # reason_fault_id: Optional[int]

    created_at: Optional[Timestamp] = None
    # accepted_at: Optional[Date]
    # in_progress_at: Optional[Date]
    # dane_at: Optional[Date]

    # status_id: Optional[int]


class OrderUpdate(BaseModel):
    # id: int
    object_id: Optional[int]

    # creator_id: Optional[int]

    fault_category_id: Optional[int]
    task_text: Optional[str]

    executor_id: Optional[int]
    commentary: Optional[str]
    reason_fault_id: Optional[int]

    created_at: Optional[Date]
    accepted_at: Optional[Date]
    in_progress_at: Optional[Date]
    dane_at: Optional[Date]

    status_id: Optional[int]
    is_viewed: Optional[bool]


class OrderGet(BaseModel):
    id: int
    object_id: Optional[ObjectGet]
    creator_id: UniversalUserGet
    fault_category_id: Optional[FaultCategoryGet]
    task_text: Optional[str]
    # order_photo: Optional[OrderPhotoGet]

    executor_id: Optional[UniversalUserGet]
    commentary: Optional[str]
    reason_fault_id: Optional[ReasonFaultGet]

    created_at: Optional[int]
    accepted_at: Optional[str]
    in_progress_at: Optional[str]
    done_at: Optional[str]

    status_id: Optional[StatusGet]
    is_viewed: Optional[bool]
