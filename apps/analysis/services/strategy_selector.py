from apps.common.enums import UnpackStrategy


def choose_strategy(shell_report: dict) -> tuple[str, str]:
    report_text = str(shell_report).lower()
    if 'qihoo' in report_text or '360' in report_text:
        return UnpackStrategy.FRIDA, '检测到 360/加固特征，优先 Frida。'
    if 'bangcle' in report_text or 'ijiami' in report_text:
        return UnpackStrategy.BLACKDEX, '检测到梆梆/爱加密特征，优先 BlackDex。'
    if 'unknown' in report_text:
        return UnpackStrategy.MANUAL, '壳类型未知，进入人工复核。'
    return UnpackStrategy.HYBRID, '默认采用 Hybrid(BlackDex -> Frida) 策略。'
