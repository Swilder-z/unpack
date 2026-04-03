from apps.shell_detector.models import UnpackStrategy


SHELL_STRATEGY_MAP = {
    'JIAGU_360': (UnpackStrategy.FRIDA, 0.92),
    'BANGCLE': (UnpackStrategy.BLACKDEX, 0.88),
    'IJIAMI': (UnpackStrategy.BLACKDEX, 0.86),
    'TENCENT_LEGU': (UnpackStrategy.BLACKDEX_THEN_FRIDA, 0.80),
    'NONE': (UnpackStrategy.NO_UNPACK, 0.95),
}


def select_unpack_strategy(shell_type: str) -> tuple[str, float]:
    normalized = (shell_type or 'UNKNOWN').upper()
    if normalized in SHELL_STRATEGY_MAP:
        return SHELL_STRATEGY_MAP[normalized]

    if 'UNKNOWN' in normalized:
        return UnpackStrategy.MANUAL_REVIEW, 0.30

    return UnpackStrategy.BLACKDEX_THEN_FRIDA, 0.55
