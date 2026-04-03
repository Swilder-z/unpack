from apps.common.enums import TaskStatus

ALLOWED_TRANSITIONS = {
    TaskStatus.PENDING: {TaskStatus.VALIDATING, TaskStatus.FAILED},
    TaskStatus.VALIDATING: {TaskStatus.IDENTIFYING_SHELL, TaskStatus.FAILED},
    TaskStatus.IDENTIFYING_SHELL: {TaskStatus.STRATEGY_SELECTED, TaskStatus.FAILED},
    TaskStatus.STRATEGY_SELECTED: {TaskStatus.RUNNING_UNPACK, TaskStatus.REVIEW_REQUIRED, TaskStatus.FAILED},
    TaskStatus.RUNNING_UNPACK: {TaskStatus.SUCCESS, TaskStatus.REVIEW_REQUIRED, TaskStatus.FAILED},
    TaskStatus.REVIEW_REQUIRED: {TaskStatus.RUNNING_UNPACK, TaskStatus.SUCCESS, TaskStatus.FAILED},
    TaskStatus.SUCCESS: set(),
    TaskStatus.FAILED: {TaskStatus.PENDING},
}


def can_transition(old: str, new: str) -> bool:
    return new in ALLOWED_TRANSITIONS.get(old, set())
