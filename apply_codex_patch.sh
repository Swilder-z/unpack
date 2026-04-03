 (cd "$(git rev-parse --show-toplevel)" && git apply --3way <<'EOF' 
diff --git a/.env.example b/.env.example
new file mode 100644
index 0000000000000000000000000000000000000000..3ae522c5428fd0ac1ea0df7469cc4f7fd8aa230f
--- /dev/null
+++ b/.env.example
@@ -0,0 +1,9 @@
+DEBUG=True
+SECRET_KEY=dev-secret-key-change-me
+ALLOWED_HOSTS=127.0.0.1,localhost
+POSTGRES_DB=android_unpack_platform
+POSTGRES_USER=postgres
+POSTGRES_PASSWORD=postgres
+POSTGRES_HOST=127.0.0.1
+POSTGRES_PORT=5432
+REDIS_URL=redis://127.0.0.1:6379/0
diff --git a/.gitignore b/.gitignore
new file mode 100644
index 0000000000000000000000000000000000000000..04458fedccbec493058555827cffbddc7ac94da1
--- /dev/null
+++ b/.gitignore
@@ -0,0 +1,7 @@
+__pycache__/
+*.pyc
+.env
+uploads/
+logs/
+artifacts/
+staticfiles/
diff --git a/README.md b/README.md
index f5d5b37cefe1447c6cd5c44b7424853d08855363..8c0991dca84ffafdd589eb754c3728556aa7050a 100644
GIT binary patch
literal 1046
zcmZ`&O-~a+7{2eXn1rKgO-%IQtx61ulAt7dgtZ-DrTgLT7Ta5a7TVInDl84kM;F0X
zkhTbv$`<-#*qPZq@fUozThxSjnrGgRXP)<C1`sdBR9T3PB_xH9PLC;ZUZ0Rvk>dv6
z@zSJ>?x7J`(<fCt`tk)_Ug4Oa!TA)&v6@2ca|T5M1{4{2j@-oqQmB#Qy4zSFUr(I&
zvYR;uKynLo+aSMA$V&63lN)|La?{CQr{_3sU;vTsp_kqvoiwQ~aoqU$_*-6^;-U%)
zV`(Oglf0<Jaqq&#<mfb3QB)QcS;Huypim3}^aW~2^~G^YN}rM?6cUjlC`gbrosY*+
zNCo%%grH&(OS%@;llpC>$V>br4l5}n3X>|Y<GYTiiovcW6s#sRtlkY!6B5{Gzy<m_
zuHT+FvI=q^|5H@Zwov4MeMcX9DJT>N<r8wi=J)7wmE=pLzRi}K92e>}+i4e^P6c{Q
zj2t~NX}U@)mUmEu20M0^WM|!a+Yh|y6rJ`ODQ1arcss3OUJ@p-riYVa97X|*v~o^2
ze~_IEW~H63MQ0my#ULx|z(&^>9lJ%0(sg=vbSU!R;UfS&KHtLfIY{&^dsWh00T2kI
z<(5}I4ah--Fo?*<OUK@Gtzxhp!0fiN5C$c9Ya4E(LH07tSm^61=7TV1uhQ+!V6(h*
zo*k_-b02b_#9?6vaT47}&r~7C!#R|C3kU#|m*D$_^=CmkbM$E6v29YYXuj&J=&dG{
z9vI!O!R%AFx<I~M0X-|UC=_S!xOK~~sh3D{W!I{~)opyE^H~7iV##fof#m*|iNr)f
zLac5<EkRfR<on=a37SdE`=nbA*56oW_7Tm0C&#9@n_=dLKVY_2qq%ec164n{`JZ%a
z-rF$#j_G0*T(q*tj;@@`Rd!;7i_|SzY5V)IR{}uKW?5~?r|Kyo#xi`q;2EFCY|>Jl
VT$&`i@4sTzNXhi9GjD5``wa*eBq9I+

literal 32
kcmezWPnki1A(5e!p@bnH$SP&XV<-UflNquZcp11D0E|)wvj6}9

diff --git a/android_unpack_platform/__init__.py b/android_unpack_platform/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..fb989c4e63d94c4e763126f5a608080c4448e631
--- /dev/null
+++ b/android_unpack_platform/__init__.py
@@ -0,0 +1,3 @@
+from .celery import app as celery_app
+
+__all__ = ('celery_app',)
diff --git a/android_unpack_platform/asgi.py b/android_unpack_platform/asgi.py
new file mode 100644
index 0000000000000000000000000000000000000000..b1b3ed40828c5ddb255615b53856a9f736277104
--- /dev/null
+++ b/android_unpack_platform/asgi.py
@@ -0,0 +1,7 @@
+import os
+
+from django.core.asgi import get_asgi_application
+
+os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'android_unpack_platform.settings')
+
+application = get_asgi_application()
diff --git a/android_unpack_platform/celery.py b/android_unpack_platform/celery.py
new file mode 100644
index 0000000000000000000000000000000000000000..0e3a2aa30e5f1f2ccc81aa861ec2ea4c012e493b
--- /dev/null
+++ b/android_unpack_platform/celery.py
@@ -0,0 +1,9 @@
+import os
+
+from celery import Celery
+
+os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'android_unpack_platform.settings')
+
+app = Celery('android_unpack_platform')
+app.config_from_object('django.conf:settings', namespace='CELERY')
+app.autodiscover_tasks()
diff --git a/android_unpack_platform/settings.py b/android_unpack_platform/settings.py
new file mode 100644
index 0000000000000000000000000000000000000000..14f7f8bb4fdd29443fae35c5a5fbc014da53fd16
--- /dev/null
+++ b/android_unpack_platform/settings.py
@@ -0,0 +1,120 @@
+from pathlib import Path
+
+import environ
+
+BASE_DIR = Path(__file__).resolve().parent.parent
+
+env = environ.Env(
+    DEBUG=(bool, True),
+    SECRET_KEY=(str, 'dev-secret-key-change-me'),
+    ALLOWED_HOSTS=(list, ['*']),
+    POSTGRES_DB=(str, 'android_unpack_platform'),
+    POSTGRES_USER=(str, 'postgres'),
+    POSTGRES_PASSWORD=(str, 'postgres'),
+    POSTGRES_HOST=(str, '127.0.0.1'),
+    POSTGRES_PORT=(int, 5432),
+    REDIS_URL=(str, 'redis://127.0.0.1:6379/0'),
+)
+
+env_file = BASE_DIR / '.env'
+if env_file.exists():
+    environ.Env.read_env(str(env_file))
+
+SECRET_KEY = env('SECRET_KEY')
+DEBUG = env('DEBUG')
+ALLOWED_HOSTS = env('ALLOWED_HOSTS')
+
+INSTALLED_APPS = [
+    'django.contrib.admin',
+    'django.contrib.auth',
+    'django.contrib.contenttypes',
+    'django.contrib.sessions',
+    'django.contrib.messages',
+    'django.contrib.staticfiles',
+    'apps.common',
+    'apps.samples',
+    'apps.analysis',
+    'apps.operations',
+]
+
+MIDDLEWARE = [
+    'django.middleware.security.SecurityMiddleware',
+    'django.contrib.sessions.middleware.SessionMiddleware',
+    'django.middleware.common.CommonMiddleware',
+    'django.middleware.csrf.CsrfViewMiddleware',
+    'django.contrib.auth.middleware.AuthenticationMiddleware',
+    'django.contrib.messages.middleware.MessageMiddleware',
+    'django.middleware.clickjacking.XFrameOptionsMiddleware',
+]
+
+ROOT_URLCONF = 'android_unpack_platform.urls'
+
+TEMPLATES = [
+    {
+        'BACKEND': 'django.template.backends.django.DjangoTemplates',
+        'DIRS': [BASE_DIR / 'templates'],
+        'APP_DIRS': True,
+        'OPTIONS': {
+            'context_processors': [
+                'django.template.context_processors.request',
+                'django.contrib.auth.context_processors.auth',
+                'django.contrib.messages.context_processors.messages',
+            ],
+        },
+    },
+]
+
+WSGI_APPLICATION = 'android_unpack_platform.wsgi.application'
+ASGI_APPLICATION = 'android_unpack_platform.asgi.application'
+
+DATABASES = {
+    'default': {
+        'ENGINE': 'django.db.backends.postgresql',
+        'NAME': env('POSTGRES_DB'),
+        'USER': env('POSTGRES_USER'),
+        'PASSWORD': env('POSTGRES_PASSWORD'),
+        'HOST': env('POSTGRES_HOST'),
+        'PORT': env('POSTGRES_PORT'),
+    }
+}
+
+AUTH_PASSWORD_VALIDATORS = [
+    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
+    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
+    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
+    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
+]
+
+LANGUAGE_CODE = 'zh-hans'
+TIME_ZONE = 'UTC'
+USE_I18N = True
+USE_TZ = True
+
+STATIC_URL = 'static/'
+STATIC_ROOT = BASE_DIR / 'staticfiles'
+
+MEDIA_URL = '/media/'
+MEDIA_ROOT = BASE_DIR / 'uploads'
+
+UPLOAD_ROOT = BASE_DIR / 'uploads'
+LOG_ROOT = BASE_DIR / 'logs'
+ARTIFACT_ROOT = BASE_DIR / 'artifacts'
+
+for path in [UPLOAD_ROOT, LOG_ROOT, ARTIFACT_ROOT]:
+    path.mkdir(parents=True, exist_ok=True)
+
+DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
+
+REDIS_URL = env('REDIS_URL')
+CELERY_BROKER_URL = REDIS_URL
+CELERY_RESULT_BACKEND = REDIS_URL
+CELERY_TASK_TRACK_STARTED = True
+CELERY_TASK_TIME_LIMIT = 60 * 20
+CELERY_TASK_SOFT_TIME_LIMIT = 60 * 15
+
+APKiD_COMMAND = ['apkid', '-j']
+APKiD_TIMEOUT = 120
+BLACKDEX_COMMAND = ['echo', 'simulate_blackdex_for']
+BLACKDEX_TIMEOUT = 300
+FRIDA_COMMAND = ['echo', 'simulate_frida_for']
+FRIDA_TIMEOUT = 300
diff --git a/android_unpack_platform/urls.py b/android_unpack_platform/urls.py
new file mode 100644
index 0000000000000000000000000000000000000000..7582528dca241613dcf4311bc87497608363837f
--- /dev/null
+++ b/android_unpack_platform/urls.py
@@ -0,0 +1,14 @@
+from django.conf import settings
+from django.conf.urls.static import static
+from django.contrib import admin
+from django.urls import include, path
+
+urlpatterns = [
+    path('admin/', admin.site.urls),
+    path('', include('apps.operations.urls')),
+    path('samples/', include('apps.samples.urls')),
+    path('analysis/', include('apps.analysis.urls')),
+]
+
+if settings.DEBUG:
+    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
diff --git a/android_unpack_platform/wsgi.py b/android_unpack_platform/wsgi.py
new file mode 100644
index 0000000000000000000000000000000000000000..cb587a0ab63c96ae3f874d0cb8628bfce1f1ff72
--- /dev/null
+++ b/android_unpack_platform/wsgi.py
@@ -0,0 +1,7 @@
+import os
+
+from django.core.wsgi import get_wsgi_application
+
+os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'android_unpack_platform.settings')
+
+application = get_wsgi_application()
diff --git a/apps/__init__.py b/apps/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/analysis/__init__.py b/apps/analysis/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/analysis/admin.py b/apps/analysis/admin.py
new file mode 100644
index 0000000000000000000000000000000000000000..9c1ca923af4b3055bd930abe6fcb7b561d209d0e
--- /dev/null
+++ b/apps/analysis/admin.py
@@ -0,0 +1,33 @@
+from django.contrib import admin
+
+from apps.analysis.models import TaskEvent, UnpackTask
+
+
+class TaskEventInline(admin.TabularInline):
+    model = TaskEvent
+    extra = 0
+    readonly_fields = ('old_status', 'new_status', 'message', 'payload', 'created_at')
+
+
+@admin.register(UnpackTask)
+class UnpackTaskAdmin(admin.ModelAdmin):
+    list_display = (
+        'id',
+        'sample',
+        'status',
+        'strategy',
+        'requires_manual_review',
+        'retry_count',
+        'created_at',
+    )
+    list_filter = ('status', 'strategy', 'requires_manual_review', 'created_at')
+    search_fields = ('sample__file_name', 'sample__sha256', 'shell_type')
+    readonly_fields = ('created_at', 'updated_at', 'started_at', 'finished_at')
+    inlines = [TaskEventInline]
+
+
+@admin.register(TaskEvent)
+class TaskEventAdmin(admin.ModelAdmin):
+    list_display = ('id', 'task', 'old_status', 'new_status', 'created_at')
+    list_filter = ('new_status', 'created_at')
+    search_fields = ('task__sample__file_name', 'message')
diff --git a/apps/analysis/apps.py b/apps/analysis/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..fbdc3dacc73d47b0159d18540e872389ab95b2a2
--- /dev/null
+++ b/apps/analysis/apps.py
@@ -0,0 +1,6 @@
+from django.apps import AppConfig
+
+
+class AnalysisConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'apps.analysis'
diff --git a/apps/analysis/migrations/0001_initial.py b/apps/analysis/migrations/0001_initial.py
new file mode 100644
index 0000000000000000000000000000000000000000..2c31c50029e0f96fa02849c62337ef65928b0219
--- /dev/null
+++ b/apps/analysis/migrations/0001_initial.py
@@ -0,0 +1,156 @@
+# Generated by Django 5.1.6 on 2026-04-03 08:12
+
+import django.db.models.deletion
+from django.db import migrations, models
+
+
+class Migration(migrations.Migration):
+
+    initial = True
+
+    dependencies = [
+        ("samples", "0001_initial"),
+    ]
+
+    operations = [
+        migrations.CreateModel(
+            name="UnpackTask",
+            fields=[
+                (
+                    "id",
+                    models.BigAutoField(
+                        auto_created=True,
+                        primary_key=True,
+                        serialize=False,
+                        verbose_name="ID",
+                    ),
+                ),
+                (
+                    "status",
+                    models.CharField(
+                        choices=[
+                            ("PENDING", "待执行"),
+                            ("VALIDATING", "校验中"),
+                            ("IDENTIFYING_SHELL", "识壳中"),
+                            ("STRATEGY_SELECTED", "策略已选择"),
+                            ("RUNNING_UNPACK", "脱壳中"),
+                            ("REVIEW_REQUIRED", "待人工复核"),
+                            ("SUCCESS", "成功"),
+                            ("FAILED", "失败"),
+                        ],
+                        default="PENDING",
+                        max_length=32,
+                    ),
+                ),
+                (
+                    "strategy",
+                    models.CharField(
+                        blank=True,
+                        choices=[
+                            ("BLACKDEX", "BlackDex"),
+                            ("FRIDA", "Frida"),
+                            ("HYBRID", "Hybrid"),
+                            ("MANUAL", "Manual"),
+                        ],
+                        default="",
+                        max_length=16,
+                    ),
+                ),
+                (
+                    "shell_type",
+                    models.CharField(blank=True, default="", max_length=128),
+                ),
+                ("shell_report", models.JSONField(blank=True, default=dict)),
+                ("retry_count", models.PositiveIntegerField(default=0)),
+                ("max_retries", models.PositiveIntegerField(default=3)),
+                ("requires_manual_review", models.BooleanField(default=False)),
+                ("review_note", models.TextField(blank=True, default="")),
+                (
+                    "celery_task_id",
+                    models.CharField(blank=True, default="", max_length=64),
+                ),
+                (
+                    "result_artifact",
+                    models.CharField(blank=True, default="", max_length=512),
+                ),
+                ("error_message", models.TextField(blank=True, default="")),
+                ("started_at", models.DateTimeField(blank=True, null=True)),
+                ("finished_at", models.DateTimeField(blank=True, null=True)),
+                ("created_at", models.DateTimeField(auto_now_add=True)),
+                ("updated_at", models.DateTimeField(auto_now=True)),
+                ("context_json", models.JSONField(blank=True, default=dict)),
+                (
+                    "sample",
+                    models.ForeignKey(
+                        on_delete=django.db.models.deletion.CASCADE,
+                        related_name="tasks",
+                        to="samples.apksample",
+                    ),
+                ),
+            ],
+            options={
+                "ordering": ["-created_at"],
+            },
+        ),
+        migrations.CreateModel(
+            name="TaskEvent",
+            fields=[
+                (
+                    "id",
+                    models.BigAutoField(
+                        auto_created=True,
+                        primary_key=True,
+                        serialize=False,
+                        verbose_name="ID",
+                    ),
+                ),
+                ("old_status", models.CharField(blank=True, default="", max_length=32)),
+                (
+                    "new_status",
+                    models.CharField(
+                        choices=[
+                            ("PENDING", "待执行"),
+                            ("VALIDATING", "校验中"),
+                            ("IDENTIFYING_SHELL", "识壳中"),
+                            ("STRATEGY_SELECTED", "策略已选择"),
+                            ("RUNNING_UNPACK", "脱壳中"),
+                            ("REVIEW_REQUIRED", "待人工复核"),
+                            ("SUCCESS", "成功"),
+                            ("FAILED", "失败"),
+                        ],
+                        max_length=32,
+                    ),
+                ),
+                ("message", models.TextField(blank=True, default="")),
+                ("payload", models.JSONField(blank=True, default=dict)),
+                ("created_at", models.DateTimeField(auto_now_add=True)),
+                (
+                    "task",
+                    models.ForeignKey(
+                        on_delete=django.db.models.deletion.CASCADE,
+                        related_name="events",
+                        to="analysis.unpacktask",
+                    ),
+                ),
+            ],
+            options={
+                "ordering": ["created_at"],
+            },
+        ),
+        migrations.AddIndex(
+            model_name="unpacktask",
+            index=models.Index(fields=["status"], name="analysis_un_status_231cd7_idx"),
+        ),
+        migrations.AddIndex(
+            model_name="unpacktask",
+            index=models.Index(
+                fields=["strategy"], name="analysis_un_strateg_38b278_idx"
+            ),
+        ),
+        migrations.AddIndex(
+            model_name="unpacktask",
+            index=models.Index(
+                fields=["created_at"], name="analysis_un_created_282ffc_idx"
+            ),
+        ),
+    ]
diff --git a/apps/analysis/migrations/__init__.py b/apps/analysis/migrations/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/analysis/models.py b/apps/analysis/models.py
new file mode 100644
index 0000000000000000000000000000000000000000..825eeaaa62b7ea297ec6fd0d99d2b91c83097de8
--- /dev/null
+++ b/apps/analysis/models.py
@@ -0,0 +1,47 @@
+from django.db import models
+
+from apps.common.enums import TaskStatus, UnpackStrategy
+from apps.samples.models import APKSample
+
+
+class UnpackTask(models.Model):
+    sample = models.ForeignKey(APKSample, on_delete=models.CASCADE, related_name='tasks')
+    status = models.CharField(max_length=32, choices=TaskStatus.choices, default=TaskStatus.PENDING)
+    strategy = models.CharField(max_length=16, choices=UnpackStrategy.choices, blank=True, default='')
+    shell_type = models.CharField(max_length=128, blank=True, default='')
+    shell_report = models.JSONField(default=dict, blank=True)
+    retry_count = models.PositiveIntegerField(default=0)
+    max_retries = models.PositiveIntegerField(default=3)
+    requires_manual_review = models.BooleanField(default=False)
+    review_note = models.TextField(blank=True, default='')
+    celery_task_id = models.CharField(max_length=64, blank=True, default='')
+    result_artifact = models.CharField(max_length=512, blank=True, default='')
+    error_message = models.TextField(blank=True, default='')
+    started_at = models.DateTimeField(null=True, blank=True)
+    finished_at = models.DateTimeField(null=True, blank=True)
+    created_at = models.DateTimeField(auto_now_add=True)
+    updated_at = models.DateTimeField(auto_now=True)
+    context_json = models.JSONField(default=dict, blank=True)
+
+    class Meta:
+        ordering = ['-created_at']
+        indexes = [
+            models.Index(fields=['status']),
+            models.Index(fields=['strategy']),
+            models.Index(fields=['created_at']),
+        ]
+
+    def __str__(self):
+        return f'Task#{self.id} sample={self.sample_id} status={self.status}'
+
+
+class TaskEvent(models.Model):
+    task = models.ForeignKey(UnpackTask, on_delete=models.CASCADE, related_name='events')
+    old_status = models.CharField(max_length=32, blank=True, default='')
+    new_status = models.CharField(max_length=32, choices=TaskStatus.choices)
+    message = models.TextField(blank=True, default='')
+    payload = models.JSONField(default=dict, blank=True)
+    created_at = models.DateTimeField(auto_now_add=True)
+
+    class Meta:
+        ordering = ['created_at']
diff --git a/apps/analysis/services/orchestrator.py b/apps/analysis/services/orchestrator.py
new file mode 100644
index 0000000000000000000000000000000000000000..83f118475f84adb22fb1dc1c36963221ea3d72cb
--- /dev/null
+++ b/apps/analysis/services/orchestrator.py
@@ -0,0 +1,11 @@
+from apps.analysis.models import UnpackTask
+from apps.analysis.tasks import run_unpack_task
+from apps.samples.models import APKSample
+
+
+def create_unpack_task_for_sample(sample: APKSample) -> UnpackTask:
+    task = UnpackTask.objects.create(sample=sample)
+    celery_res = run_unpack_task.delay(task.id)
+    task.celery_task_id = celery_res.id
+    task.save(update_fields=['celery_task_id', 'updated_at'])
+    return task
diff --git a/apps/analysis/services/runners/blackdex_runner.py b/apps/analysis/services/runners/blackdex_runner.py
new file mode 100644
index 0000000000000000000000000000000000000000..fb1c6eadc2339781ea898dc970ca8d7e3abeb0a7
--- /dev/null
+++ b/apps/analysis/services/runners/blackdex_runner.py
@@ -0,0 +1,33 @@
+import subprocess
+from pathlib import Path
+
+from django.conf import settings
+
+
+class RunnerError(Exception):
+    pass
+
+
+class BlackDexRunner:
+    def run(self, apk_path: str, output_dir: Path) -> Path:
+        output_dir.mkdir(parents=True, exist_ok=True)
+        out_file = output_dir / 'blackdex_unpacked.apk'
+        cmd = [*settings.BLACKDEX_COMMAND, apk_path]
+        try:
+            result = subprocess.run(
+                cmd,
+                capture_output=True,
+                text=True,
+                timeout=settings.BLACKDEX_TIMEOUT,
+                check=False,
+            )
+        except subprocess.TimeoutExpired as exc:
+            raise RunnerError('BlackDex 执行超时') from exc
+        except OSError as exc:
+            raise RunnerError(f'BlackDex 启动失败: {exc}') from exc
+
+        if result.returncode != 0:
+            raise RunnerError(f'BlackDex 执行失败: {result.stderr.strip()}')
+
+        out_file.write_text(result.stdout or 'blackdex output placeholder', encoding='utf-8')
+        return out_file
diff --git a/apps/analysis/services/runners/frida_runner.py b/apps/analysis/services/runners/frida_runner.py
new file mode 100644
index 0000000000000000000000000000000000000000..19f6bd533b2162b6ec016e4cb375fafce25029e5
--- /dev/null
+++ b/apps/analysis/services/runners/frida_runner.py
@@ -0,0 +1,31 @@
+import subprocess
+from pathlib import Path
+
+from django.conf import settings
+
+from apps.analysis.services.runners.blackdex_runner import RunnerError
+
+
+class FridaRunner:
+    def run(self, apk_path: str, output_dir: Path) -> Path:
+        output_dir.mkdir(parents=True, exist_ok=True)
+        out_file = output_dir / 'frida_unpacked.apk'
+        cmd = [*settings.FRIDA_COMMAND, apk_path]
+        try:
+            result = subprocess.run(
+                cmd,
+                capture_output=True,
+                text=True,
+                timeout=settings.FRIDA_TIMEOUT,
+                check=False,
+            )
+        except subprocess.TimeoutExpired as exc:
+            raise RunnerError('Frida 执行超时') from exc
+        except OSError as exc:
+            raise RunnerError(f'Frida 启动失败: {exc}') from exc
+
+        if result.returncode != 0:
+            raise RunnerError(f'Frida 执行失败: {result.stderr.strip()}')
+
+        out_file.write_text(result.stdout or 'frida output placeholder', encoding='utf-8')
+        return out_file
diff --git a/apps/analysis/services/shell_identifier.py b/apps/analysis/services/shell_identifier.py
new file mode 100644
index 0000000000000000000000000000000000000000..9e0c01664db578fe6cca7166a22b5e9a0b2361dc
--- /dev/null
+++ b/apps/analysis/services/shell_identifier.py
@@ -0,0 +1,32 @@
+import json
+import subprocess
+
+from django.conf import settings
+
+
+class ShellIdentifierError(Exception):
+    pass
+
+
+def identify_shell(apk_path: str) -> dict:
+    cmd = [*settings.APKiD_COMMAND, apk_path]
+    try:
+        result = subprocess.run(
+            cmd,
+            capture_output=True,
+            text=True,
+            timeout=settings.APKiD_TIMEOUT,
+            check=False,
+        )
+    except subprocess.TimeoutExpired as exc:
+        raise ShellIdentifierError('APKiD 执行超时') from exc
+    except OSError as exc:
+        raise ShellIdentifierError(f'APKiD 执行失败: {exc}') from exc
+
+    if result.returncode != 0:
+        raise ShellIdentifierError(f'APKiD 返回非零状态: {result.stderr.strip()}')
+
+    try:
+        return json.loads(result.stdout)
+    except json.JSONDecodeError as exc:
+        raise ShellIdentifierError('APKiD 输出解析失败') from exc
diff --git a/apps/analysis/services/state_machine.py b/apps/analysis/services/state_machine.py
new file mode 100644
index 0000000000000000000000000000000000000000..a515b37d8d7c9b8fb3c8ac794f1086c740773191
--- /dev/null
+++ b/apps/analysis/services/state_machine.py
@@ -0,0 +1,16 @@
+from apps.common.enums import TaskStatus
+
+ALLOWED_TRANSITIONS = {
+    TaskStatus.PENDING: {TaskStatus.VALIDATING, TaskStatus.FAILED},
+    TaskStatus.VALIDATING: {TaskStatus.IDENTIFYING_SHELL, TaskStatus.FAILED},
+    TaskStatus.IDENTIFYING_SHELL: {TaskStatus.STRATEGY_SELECTED, TaskStatus.FAILED},
+    TaskStatus.STRATEGY_SELECTED: {TaskStatus.RUNNING_UNPACK, TaskStatus.REVIEW_REQUIRED, TaskStatus.FAILED},
+    TaskStatus.RUNNING_UNPACK: {TaskStatus.SUCCESS, TaskStatus.REVIEW_REQUIRED, TaskStatus.FAILED},
+    TaskStatus.REVIEW_REQUIRED: {TaskStatus.RUNNING_UNPACK, TaskStatus.SUCCESS, TaskStatus.FAILED},
+    TaskStatus.SUCCESS: set(),
+    TaskStatus.FAILED: {TaskStatus.PENDING},
+}
+
+
+def can_transition(old: str, new: str) -> bool:
+    return new in ALLOWED_TRANSITIONS.get(old, set())
diff --git a/apps/analysis/services/strategy_selector.py b/apps/analysis/services/strategy_selector.py
new file mode 100644
index 0000000000000000000000000000000000000000..985799fd299764d30acce661d5339bd2c3b7571d
--- /dev/null
+++ b/apps/analysis/services/strategy_selector.py
@@ -0,0 +1,12 @@
+from apps.common.enums import UnpackStrategy
+
+
+def choose_strategy(shell_report: dict) -> tuple[str, str]:
+    report_text = str(shell_report).lower()
+    if 'qihoo' in report_text or '360' in report_text:
+        return UnpackStrategy.FRIDA, '检测到 360/加固特征，优先 Frida。'
+    if 'bangcle' in report_text or 'ijiami' in report_text:
+        return UnpackStrategy.BLACKDEX, '检测到梆梆/爱加密特征，优先 BlackDex。'
+    if 'unknown' in report_text:
+        return UnpackStrategy.MANUAL, '壳类型未知，进入人工复核。'
+    return UnpackStrategy.HYBRID, '默认采用 Hybrid(BlackDex -> Frida) 策略。'
diff --git a/apps/analysis/services/task_service.py b/apps/analysis/services/task_service.py
new file mode 100644
index 0000000000000000000000000000000000000000..bd9b53e76fbd72fc0e75b4b11d686813caaaf8b7
--- /dev/null
+++ b/apps/analysis/services/task_service.py
@@ -0,0 +1,26 @@
+from django.utils import timezone
+
+from apps.analysis.models import TaskEvent, UnpackTask
+from apps.analysis.services.state_machine import can_transition
+
+
+def update_task_status(task: UnpackTask, new_status: str, message: str = '', payload: dict | None = None) -> None:
+    payload = payload or {}
+    if not can_transition(task.status, new_status) and task.status != new_status:
+        raise ValueError(f'非法状态流转: {task.status} -> {new_status}')
+
+    old_status = task.status
+    task.status = new_status
+    if new_status == 'RUNNING_UNPACK' and task.started_at is None:
+        task.started_at = timezone.now()
+    if new_status in {'SUCCESS', 'FAILED'}:
+        task.finished_at = timezone.now()
+    task.save(update_fields=['status', 'started_at', 'finished_at', 'updated_at'])
+
+    TaskEvent.objects.create(
+        task=task,
+        old_status=old_status,
+        new_status=new_status,
+        message=message,
+        payload=payload,
+    )
diff --git a/apps/analysis/tasks.py b/apps/analysis/tasks.py
new file mode 100644
index 0000000000000000000000000000000000000000..a79763be1152b0313ea5e97b69a137fb7ae8eec4
--- /dev/null
+++ b/apps/analysis/tasks.py
@@ -0,0 +1,86 @@
+from pathlib import Path
+
+from celery import shared_task
+from django.conf import settings
+from django.core.exceptions import ValidationError
+from django.db import transaction
+
+from apps.analysis.models import UnpackTask
+from apps.analysis.services.runners.blackdex_runner import BlackDexRunner, RunnerError
+from apps.analysis.services.runners.frida_runner import FridaRunner
+from apps.analysis.services.shell_identifier import ShellIdentifierError, identify_shell
+from apps.analysis.services.strategy_selector import choose_strategy
+from apps.analysis.services.task_service import update_task_status
+from apps.common.enums import TaskStatus, UnpackStrategy
+from apps.samples.services import validate_apk_file
+
+
+@shared_task(bind=True, autoretry_for=(RunnerError,), retry_backoff=True, retry_kwargs={'max_retries': 3})
+def run_unpack_task(self, task_id: int):
+    task = UnpackTask.objects.select_related('sample').get(id=task_id)
+
+    with transaction.atomic():
+        update_task_status(task, TaskStatus.VALIDATING, '开始校验 APK')
+    try:
+        with task.sample.file.open('rb') as f:
+            validate_apk_file(f)
+    except ValidationError as exc:
+        task.error_message = str(exc)
+        task.save(update_fields=['error_message', 'updated_at'])
+        update_task_status(task, TaskStatus.FAILED, 'APK 校验失败')
+        return
+
+    update_task_status(task, TaskStatus.IDENTIFYING_SHELL, '开始 APKiD 识壳')
+    try:
+        shell_report = identify_shell(task.sample.file.path)
+        task.shell_report = shell_report
+        task.shell_type = str(shell_report)[:120]
+        task.save(update_fields=['shell_report', 'shell_type', 'updated_at'])
+    except ShellIdentifierError as exc:
+        task.error_message = str(exc)
+        task.requires_manual_review = True
+        task.save(update_fields=['error_message', 'requires_manual_review', 'updated_at'])
+        update_task_status(task, TaskStatus.REVIEW_REQUIRED, '识壳失败，转人工复核')
+        return
+
+    strategy, reason = choose_strategy(task.shell_report)
+    task.strategy = strategy
+    task.context_json = {'strategy_reason': reason}
+    task.save(update_fields=['strategy', 'context_json', 'updated_at'])
+    update_task_status(task, TaskStatus.STRATEGY_SELECTED, reason)
+
+    if strategy == UnpackStrategy.MANUAL:
+        task.requires_manual_review = True
+        task.save(update_fields=['requires_manual_review', 'updated_at'])
+        update_task_status(task, TaskStatus.REVIEW_REQUIRED, '策略要求人工复核')
+        return
+
+    update_task_status(task, TaskStatus.RUNNING_UNPACK, '开始执行脱壳')
+    out_dir = Path(settings.ARTIFACT_ROOT) / f'task_{task.id}'
+
+    try:
+        if strategy == UnpackStrategy.BLACKDEX:
+            artifact = BlackDexRunner().run(task.sample.file.path, out_dir)
+        elif strategy == UnpackStrategy.FRIDA:
+            artifact = FridaRunner().run(task.sample.file.path, out_dir)
+        else:
+            try:
+                artifact = BlackDexRunner().run(task.sample.file.path, out_dir)
+            except RunnerError:
+                artifact = FridaRunner().run(task.sample.file.path, out_dir)
+
+        task.result_artifact = str(artifact)
+        task.error_message = ''
+        task.save(update_fields=['result_artifact', 'error_message', 'updated_at'])
+        update_task_status(task, TaskStatus.SUCCESS, '脱壳任务完成')
+    except RunnerError as exc:
+        task.retry_count += 1
+        task.error_message = str(exc)
+        if task.retry_count >= task.max_retries:
+            task.requires_manual_review = True
+            task.save(update_fields=['retry_count', 'error_message', 'requires_manual_review', 'updated_at'])
+            update_task_status(task, TaskStatus.REVIEW_REQUIRED, '脱壳多次失败，转人工复核')
+        else:
+            task.save(update_fields=['retry_count', 'error_message', 'updated_at'])
+            update_task_status(task, TaskStatus.FAILED, '脱壳失败，等待重试')
+            raise
diff --git a/apps/analysis/urls.py b/apps/analysis/urls.py
new file mode 100644
index 0000000000000000000000000000000000000000..c5975a2af90f4e1a2c40ffbabbe6d04ffcc2933e
--- /dev/null
+++ b/apps/analysis/urls.py
@@ -0,0 +1,10 @@
+from django.urls import path
+
+from apps.analysis import views
+
+app_name = 'analysis'
+
+urlpatterns = [
+    path('tasks/<int:task_id>/', views.task_detail, name='task_detail'),
+    path('tasks/<int:task_id>/retry/', views.retry_task, name='retry_task'),
+]
diff --git a/apps/analysis/views.py b/apps/analysis/views.py
new file mode 100644
index 0000000000000000000000000000000000000000..a7fd89e80c422292a7c99fe74d9e5e7ed80fac9b
--- /dev/null
+++ b/apps/analysis/views.py
@@ -0,0 +1,20 @@
+from django.shortcuts import get_object_or_404, redirect, render
+
+from apps.analysis.models import UnpackTask
+from apps.analysis.tasks import run_unpack_task
+
+
+def task_detail(request, task_id: int):
+    task = get_object_or_404(UnpackTask.objects.select_related('sample'), id=task_id)
+    return render(request, 'analysis/task_detail.html', {'task': task})
+
+
+def retry_task(request, task_id: int):
+    task = get_object_or_404(UnpackTask, id=task_id)
+    if task.status in {'FAILED', 'REVIEW_REQUIRED'}:
+        task.status = 'PENDING'
+        task.save(update_fields=['status', 'updated_at'])
+        res = run_unpack_task.delay(task.id)
+        task.celery_task_id = res.id
+        task.save(update_fields=['celery_task_id', 'updated_at'])
+    return redirect('analysis:task_detail', task_id=task_id)
diff --git a/apps/common/__init__.py b/apps/common/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/common/apps.py b/apps/common/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..f992f88cd4b35a8cddbb09d043d25dc17b0affa3
--- /dev/null
+++ b/apps/common/apps.py
@@ -0,0 +1,6 @@
+from django.apps import AppConfig
+
+
+class CommonConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'apps.common'
diff --git a/apps/common/enums.py b/apps/common/enums.py
new file mode 100644
index 0000000000000000000000000000000000000000..a0ad3dde2a26b67d352ab4f7a507100185b6eff4
--- /dev/null
+++ b/apps/common/enums.py
@@ -0,0 +1,19 @@
+from django.db import models
+
+
+class TaskStatus(models.TextChoices):
+    PENDING = 'PENDING', '待执行'
+    VALIDATING = 'VALIDATING', '校验中'
+    IDENTIFYING_SHELL = 'IDENTIFYING_SHELL', '识壳中'
+    STRATEGY_SELECTED = 'STRATEGY_SELECTED', '策略已选择'
+    RUNNING_UNPACK = 'RUNNING_UNPACK', '脱壳中'
+    REVIEW_REQUIRED = 'REVIEW_REQUIRED', '待人工复核'
+    SUCCESS = 'SUCCESS', '成功'
+    FAILED = 'FAILED', '失败'
+
+
+class UnpackStrategy(models.TextChoices):
+    BLACKDEX = 'BLACKDEX', 'BlackDex'
+    FRIDA = 'FRIDA', 'Frida'
+    HYBRID = 'HYBRID', 'Hybrid'
+    MANUAL = 'MANUAL', 'Manual'
diff --git a/apps/execution/__init__.py b/apps/execution/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/execution/apps.py b/apps/execution/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..dfb26add02441e46032f102f074784c63688e483
--- /dev/null
+++ b/apps/execution/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class ExecutionConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'apps.execution'
+    verbose_name = '执行引擎'
diff --git a/apps/execution/blackdex_runner.py b/apps/execution/blackdex_runner.py
new file mode 100644
index 0000000000000000000000000000000000000000..e41e9e465cf32e6e77ad0a2888d3fd634d380d6d
--- /dev/null
+++ b/apps/execution/blackdex_runner.py
@@ -0,0 +1,44 @@
+import subprocess
+from pathlib import Path
+
+from django.conf import settings
+
+
+class RunnerError(RuntimeError):
+    pass
+
+
+class BlackDexRunner:
+    def __init__(self):
+        self.base_cmd = getattr(settings, 'BLACKDEX_COMMAND', ['echo', 'blackdex'])
+        self.timeout = int(getattr(settings, 'BLACKDEX_TIMEOUT', 300))
+
+    def run(self, apk_path: str, output_dir: Path) -> dict:
+        output_dir.mkdir(parents=True, exist_ok=True)
+        out_file = output_dir / 'blackdex_unpacked.apk'
+        cmd = [*self.base_cmd, apk_path]
+
+        try:
+            result = subprocess.run(
+                cmd,
+                capture_output=True,
+                text=True,
+                timeout=self.timeout,
+                check=False,
+            )
+        except subprocess.TimeoutExpired as exc:
+            raise RunnerError('BlackDex 执行超时') from exc
+        except OSError as exc:
+            raise RunnerError(f'BlackDex 启动失败: {exc}') from exc
+
+        if result.returncode != 0:
+            raise RunnerError(f'BlackDex 执行失败: {result.stderr.strip() or result.stdout.strip()}')
+
+        out_file.write_text(result.stdout or 'blackdex placeholder artifact', encoding='utf-8')
+        return {
+            'tool': 'blackdex',
+            'artifact': str(out_file),
+            'stdout': result.stdout,
+            'stderr': result.stderr,
+            'returncode': result.returncode,
+        }
diff --git a/apps/execution/emulator_manager.py b/apps/execution/emulator_manager.py
new file mode 100644
index 0000000000000000000000000000000000000000..bed0922aaeb8114c4b311550cd55eede3e61920c
--- /dev/null
+++ b/apps/execution/emulator_manager.py
@@ -0,0 +1,49 @@
+import subprocess
+
+from django.conf import settings
+
+
+class EmulatorError(RuntimeError):
+    pass
+
+
+class EmulatorManager:
+    def __init__(self):
+        self.start_cmd = getattr(settings, 'EMULATOR_START_COMMAND', ['echo', 'start_emulator'])
+        self.stop_cmd = getattr(settings, 'EMULATOR_STOP_COMMAND', ['echo', 'stop_emulator'])
+        self.status_cmd = getattr(settings, 'EMULATOR_STATUS_COMMAND', ['echo', 'online'])
+        self.install_cmd = getattr(settings, 'EMULATOR_INSTALL_APK_COMMAND', ['echo', 'install_apk'])
+        self.timeout = int(getattr(settings, 'EMULATOR_TIMEOUT', 180))
+
+    def start(self) -> str:
+        return self._run(self.start_cmd, '启动模拟器失败')
+
+    def stop(self) -> str:
+        return self._run(self.stop_cmd, '关闭模拟器失败')
+
+    def is_online(self) -> bool:
+        output = self._run(self.status_cmd, '检查模拟器在线状态失败')
+        return 'online' in output.lower() or 'device' in output.lower()
+
+    def install_apk(self, apk_path: str) -> str:
+        cmd = [*self.install_cmd, apk_path]
+        return self._run(cmd, '安装APK到模拟器失败')
+
+    def _run(self, cmd: list[str], error_prefix: str) -> str:
+        try:
+            result = subprocess.run(
+                cmd,
+                capture_output=True,
+                text=True,
+                timeout=self.timeout,
+                check=False,
+            )
+        except subprocess.TimeoutExpired as exc:
+            raise EmulatorError(f'{error_prefix}: 命令超时') from exc
+        except OSError as exc:
+            raise EmulatorError(f'{error_prefix}: 系统错误 {exc}') from exc
+
+        if result.returncode != 0:
+            raise EmulatorError(f'{error_prefix}: {result.stderr.strip() or result.stdout.strip()}')
+
+        return (result.stdout or '').strip()
diff --git a/apps/execution/frida_runner.py b/apps/execution/frida_runner.py
new file mode 100644
index 0000000000000000000000000000000000000000..97299969fe7c1654c3506936dfa5bb0d1dd7f328
--- /dev/null
+++ b/apps/execution/frida_runner.py
@@ -0,0 +1,42 @@
+import subprocess
+from pathlib import Path
+
+from django.conf import settings
+
+from apps.execution.blackdex_runner import RunnerError
+
+
+class FridaRunner:
+    def __init__(self):
+        self.base_cmd = getattr(settings, 'FRIDA_COMMAND', ['echo', 'frida'])
+        self.timeout = int(getattr(settings, 'FRIDA_TIMEOUT', 300))
+
+    def run(self, apk_path: str, output_dir: Path) -> dict:
+        output_dir.mkdir(parents=True, exist_ok=True)
+        out_file = output_dir / 'frida_unpacked.apk'
+        cmd = [*self.base_cmd, apk_path]
+
+        try:
+            result = subprocess.run(
+                cmd,
+                capture_output=True,
+                text=True,
+                timeout=self.timeout,
+                check=False,
+            )
+        except subprocess.TimeoutExpired as exc:
+            raise RunnerError('Frida 执行超时') from exc
+        except OSError as exc:
+            raise RunnerError(f'Frida 启动失败: {exc}') from exc
+
+        if result.returncode != 0:
+            raise RunnerError(f'Frida 执行失败: {result.stderr.strip() or result.stdout.strip()}')
+
+        out_file.write_text(result.stdout or 'frida placeholder artifact', encoding='utf-8')
+        return {
+            'tool': 'frida',
+            'artifact': str(out_file),
+            'stdout': result.stdout,
+            'stderr': result.stderr,
+            'returncode': result.returncode,
+        }
diff --git a/apps/execution/services.py b/apps/execution/services.py
new file mode 100644
index 0000000000000000000000000000000000000000..f5ea7d9367f68ace5739bab918942177cbab9aa4
--- /dev/null
+++ b/apps/execution/services.py
@@ -0,0 +1,161 @@
+from pathlib import Path
+
+from django.conf import settings
+from django.db import transaction
+from django.utils import timezone
+
+from apps.execution.blackdex_runner import BlackDexRunner, RunnerError
+from apps.execution.emulator_manager import EmulatorError, EmulatorManager
+from apps.execution.frida_runner import FridaRunner
+from apps.execution.task_logger import log_stage
+from apps.shell_detector.models import UnpackStrategy
+from apps.unpack_tasks.models import TaskStatus, UnpackJob
+
+
+def execute_unpack_flow(job: UnpackJob) -> dict:
+    artifact_dir = Path(getattr(settings, 'ARTIFACT_DIR', settings.BASE_DIR / 'artifacts')) / f'job_{job.id}'
+    artifact_dir.mkdir(parents=True, exist_ok=True)
+
+    _update_status(job, TaskStatus.IDENTIFYING_SHELL, '开始识壳阶段')
+    if job.shell_detection_id is None:
+        _fail_job(job, '缺少 shell_detection 结果，无法继续')
+        return {'ok': False, 'reason': 'missing_shell_detection'}
+
+    _update_status(job, TaskStatus.SELECTING_STRATEGY, '开始策略选择')
+    strategy = job.strategy or job.shell_detection.strategy
+    job.strategy = strategy
+    job.artifact_dir = str(artifact_dir)
+    job.save(update_fields=['strategy', 'artifact_dir', 'updated_at'])
+    log_stage(job, 'SELECTING_STRATEGY', f'策略为 {strategy}', data={'strategy': strategy})
+
+    if strategy == UnpackStrategy.NO_UNPACK:
+        _update_status(job, TaskStatus.SUCCESS, '无需脱壳，流程结束')
+        _finish_job(job)
+        return {'ok': True, 'status': TaskStatus.SUCCESS, 'artifacts': []}
+
+    if strategy == UnpackStrategy.MANUAL_REVIEW:
+        job.requires_review = True
+        job.save(update_fields=['requires_review', 'updated_at'])
+        _update_status(job, TaskStatus.REVIEW_REQUIRED, '策略要求人工复核')
+        _finish_job(job)
+        return {'ok': False, 'status': TaskStatus.REVIEW_REQUIRED}
+
+    artifacts: list[str] = []
+    stage_errors: list[str] = []
+    manager = EmulatorManager()
+
+    if strategy in {UnpackStrategy.FRIDA, UnpackStrategy.BLACKDEX_THEN_FRIDA}:
+        try:
+            _update_status(job, TaskStatus.STARTING_EMULATOR, '启动模拟器')
+            log_stage(job, 'STARTING_EMULATOR', '准备启动模拟器')
+            manager.start()
+            if not manager.is_online():
+                raise EmulatorError('模拟器未在线')
+
+            _update_status(job, TaskStatus.INSTALLING_APK, '向模拟器安装APK')
+            manager.install_apk(job.sample.file.path)
+            log_stage(job, 'INSTALLING_APK', 'APK 安装完成')
+        except EmulatorError as exc:
+            stage_errors.append(str(exc))
+            log_stage(job, 'EMULATOR', str(exc), level='ERROR')
+            if strategy == UnpackStrategy.FRIDA:
+                return _handle_failure_or_review(job, stage_errors)
+
+    if strategy in {UnpackStrategy.BLACKDEX, UnpackStrategy.BLACKDEX_THEN_FRIDA}:
+        try:
+            _update_status(job, TaskStatus.RUNNING_BLACKDEX, '运行 BlackDex')
+            blackdex_result = BlackDexRunner().run(job.sample.file.path, artifact_dir)
+            artifacts.append(blackdex_result['artifact'])
+            log_stage(job, 'RUNNING_BLACKDEX', 'BlackDex 执行成功', data=blackdex_result)
+        except RunnerError as exc:
+            stage_errors.append(str(exc))
+            log_stage(job, 'RUNNING_BLACKDEX', str(exc), level='ERROR')
+            if strategy == UnpackStrategy.BLACKDEX:
+                return _handle_failure_or_review(job, stage_errors)
+
+    if strategy in {UnpackStrategy.FRIDA, UnpackStrategy.BLACKDEX_THEN_FRIDA}:
+        try:
+            _update_status(job, TaskStatus.RUNNING_FRIDA, '运行 Frida')
+            frida_result = FridaRunner().run(job.sample.file.path, artifact_dir)
+            artifacts.append(frida_result['artifact'])
+            log_stage(job, 'RUNNING_FRIDA', 'Frida 执行成功', data=frida_result)
+        except RunnerError as exc:
+            stage_errors.append(str(exc))
+            log_stage(job, 'RUNNING_FRIDA', str(exc), level='ERROR')
+            if strategy == UnpackStrategy.FRIDA:
+                return _handle_failure_or_review(job, stage_errors)
+
+    _update_status(job, TaskStatus.COLLECTING_ARTIFACTS, '收集产物文件')
+    existing_artifacts = [p for p in artifacts if Path(p).exists()]
+
+    job.artifact_paths = existing_artifacts
+    job.result_summary = {
+        'artifact_count': len(existing_artifacts),
+        'errors': stage_errors,
+        'strategy': strategy,
+    }
+    job.save(update_fields=['artifact_paths', 'result_summary', 'updated_at'])
+
+    try:
+        manager.stop()
+    except EmulatorError as exc:
+        log_stage(job, 'STOP_EMULATOR', f'模拟器关闭失败: {exc}', level='WARNING')
+
+    if existing_artifacts and not stage_errors:
+        _update_status(job, TaskStatus.SUCCESS, '任务执行成功')
+        _finish_job(job)
+        return {'ok': True, 'status': TaskStatus.SUCCESS, 'artifacts': existing_artifacts}
+
+    if existing_artifacts:
+        _update_status(job, TaskStatus.PARTIAL_SUCCESS, '部分阶段成功，需复核')
+        job.requires_review = True
+        job.save(update_fields=['requires_review', 'updated_at'])
+        _finish_job(job)
+        return {'ok': True, 'status': TaskStatus.PARTIAL_SUCCESS, 'artifacts': existing_artifacts, 'errors': stage_errors}
+
+    return _handle_failure_or_review(job, stage_errors)
+
+
+def _handle_failure_or_review(job: UnpackJob, errors: list[str]) -> dict:
+    joined = '; '.join(errors) if errors else '未知错误'
+    if job.retry_count < job.max_retries:
+        job.retry_count += 1
+        job.error_message = joined
+        job.status = TaskStatus.FAILED
+        job.save(update_fields=['retry_count', 'error_message', 'status', 'updated_at'])
+        log_stage(job, 'FAILED', f'任务失败，准备重试({job.retry_count}/{job.max_retries})', level='ERROR')
+        raise RuntimeError(joined)
+
+    job.error_message = joined
+    job.requires_review = True
+    job.status = TaskStatus.REVIEW_REQUIRED
+    job.save(update_fields=['error_message', 'requires_review', 'status', 'updated_at'])
+    log_stage(job, 'REVIEW_REQUIRED', '重试耗尽，转人工复核', level='ERROR', data={'errors': errors})
+    _finish_job(job)
+    return {'ok': False, 'status': TaskStatus.REVIEW_REQUIRED, 'errors': errors}
+
+
+def _update_status(job: UnpackJob, new_status: str, message: str) -> None:
+    with transaction.atomic():
+        locked = UnpackJob.objects.select_for_update().get(id=job.id)
+        if not locked.can_transition_to(new_status) and locked.status != new_status:
+            raise RuntimeError(f'非法状态流转: {locked.status} -> {new_status}')
+
+        locked.status = new_status
+        locked.save(update_fields=['status', 'updated_at'])
+        log_stage(locked, new_status, message)
+
+    job.status = new_status
+
+
+def _fail_job(job: UnpackJob, reason: str) -> None:
+    job.status = TaskStatus.FAILED
+    job.error_message = reason
+    job.save(update_fields=['status', 'error_message', 'updated_at'])
+    log_stage(job, 'FAILED', reason, level='ERROR')
+
+
+def _finish_job(job: UnpackJob) -> None:
+    if job.finished_at is None:
+        job.finished_at = timezone.now()
+        job.save(update_fields=['finished_at', 'updated_at'])
diff --git a/apps/execution/task_logger.py b/apps/execution/task_logger.py
new file mode 100644
index 0000000000000000000000000000000000000000..0ce7450b6daf150f835d2ed05b0cec1b3883ceb6
--- /dev/null
+++ b/apps/execution/task_logger.py
@@ -0,0 +1,11 @@
+from apps.unpack_tasks.models import TaskExecutionLog, UnpackJob
+
+
+def log_stage(job: UnpackJob, stage: str, message: str, level: str = 'INFO', data: dict | None = None) -> None:
+    TaskExecutionLog.objects.create(
+        job=job,
+        stage=stage,
+        level=level,
+        message=message,
+        data=data or {},
+    )
diff --git a/apps/operations/__init__.py b/apps/operations/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/operations/apps.py b/apps/operations/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..6707f1a5104186828815a7f74c37db2483ab057e
--- /dev/null
+++ b/apps/operations/apps.py
@@ -0,0 +1,6 @@
+from django.apps import AppConfig
+
+
+class OperationsConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'apps.operations'
diff --git a/apps/operations/urls.py b/apps/operations/urls.py
new file mode 100644
index 0000000000000000000000000000000000000000..3850e92e8b4f5c41c75a853611b4bb68829f3aed
--- /dev/null
+++ b/apps/operations/urls.py
@@ -0,0 +1,9 @@
+from django.urls import path
+
+from apps.operations import views
+
+app_name = 'operations'
+
+urlpatterns = [
+    path('', views.dashboard, name='task_list'),
+]
diff --git a/apps/operations/views.py b/apps/operations/views.py
new file mode 100644
index 0000000000000000000000000000000000000000..156ef7ea2f78b0190787fe585ecc13f3f98db7be
--- /dev/null
+++ b/apps/operations/views.py
@@ -0,0 +1,19 @@
+from django.db.models import Count
+from django.shortcuts import render
+
+from apps.analysis.models import UnpackTask
+
+
+def dashboard(request):
+    status = request.GET.get('status', '').strip()
+    qs = UnpackTask.objects.select_related('sample')
+    if status:
+        qs = qs.filter(status=status)
+
+    task_stats = UnpackTask.objects.values('status').annotate(total=Count('id')).order_by('status')
+    context = {
+        'tasks': qs[:100],
+        'task_stats': task_stats,
+        'current_status': status,
+    }
+    return render(request, 'operations/task_list.html', context)
diff --git a/apps/samples/__init__.py b/apps/samples/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/samples/admin.py b/apps/samples/admin.py
new file mode 100644
index 0000000000000000000000000000000000000000..41c9cdd890c65e5878dc996309fd2e772d9dd9cc
--- /dev/null
+++ b/apps/samples/admin.py
@@ -0,0 +1,21 @@
+from django.contrib import admin
+
+from apps.samples.models import APKSample
+
+
+@admin.register(APKSample)
+class APKSampleAdmin(admin.ModelAdmin):
+    list_display = (
+        'id',
+        'file_name',
+        'sha256',
+        'package_name',
+        'version_name',
+        'version_code',
+        'file_size',
+        'is_valid_apk',
+        'uploaded_at',
+    )
+    list_filter = ('is_valid_apk', 'uploaded_at')
+    search_fields = ('file_name', 'sha256', 'package_name')
+    readonly_fields = ('uploaded_at', 'updated_at')
diff --git a/apps/samples/apps.py b/apps/samples/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..42519fdb2100f4706d42aa7a767f37a97053901d
--- /dev/null
+++ b/apps/samples/apps.py
@@ -0,0 +1,6 @@
+from django.apps import AppConfig
+
+
+class SamplesConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'apps.samples'
diff --git a/apps/samples/forms.py b/apps/samples/forms.py
new file mode 100644
index 0000000000000000000000000000000000000000..f98ba7624461f94e6135941814eac6464048f2be
--- /dev/null
+++ b/apps/samples/forms.py
@@ -0,0 +1,11 @@
+from django import forms
+
+
+class APKUploadForm(forms.Form):
+    file = forms.FileField(label='APK 文件')
+
+    def clean_file(self):
+        file = self.cleaned_data['file']
+        if not file.name.lower().endswith('.apk'):
+            raise forms.ValidationError('仅支持 .apk 文件。')
+        return file
diff --git a/apps/samples/migrations/0001_initial.py b/apps/samples/migrations/0001_initial.py
new file mode 100644
index 0000000000000000000000000000000000000000..db560e85e18b23359ce269357bbd97bbcd0ffeef
--- /dev/null
+++ b/apps/samples/migrations/0001_initial.py
@@ -0,0 +1,60 @@
+# Generated by Django 5.1.6 on 2026-04-03 08:12
+
+from django.db import migrations, models
+
+
+class Migration(migrations.Migration):
+
+    initial = True
+
+    dependencies = []
+
+    operations = [
+        migrations.CreateModel(
+            name="APKSample",
+            fields=[
+                (
+                    "id",
+                    models.BigAutoField(
+                        auto_created=True,
+                        primary_key=True,
+                        serialize=False,
+                        verbose_name="ID",
+                    ),
+                ),
+                ("file", models.FileField(upload_to="apks/%Y/%m/%d/")),
+                ("file_name", models.CharField(max_length=255)),
+                ("sha256", models.CharField(max_length=64, unique=True)),
+                (
+                    "package_name",
+                    models.CharField(blank=True, default="", max_length=255),
+                ),
+                (
+                    "version_name",
+                    models.CharField(blank=True, default="", max_length=128),
+                ),
+                (
+                    "version_code",
+                    models.CharField(blank=True, default="", max_length=64),
+                ),
+                ("file_size", models.BigIntegerField(default=0)),
+                ("mime_type", models.CharField(blank=True, default="", max_length=128)),
+                ("uploaded_at", models.DateTimeField(auto_now_add=True)),
+                ("meta_json", models.JSONField(blank=True, default=dict)),
+            ],
+            options={
+                "ordering": ["-uploaded_at"],
+                "indexes": [
+                    models.Index(
+                        fields=["sha256"], name="samples_apk_sha256_68a52d_idx"
+                    ),
+                    models.Index(
+                        fields=["package_name"], name="samples_apk_package_6bb837_idx"
+                    ),
+                    models.Index(
+                        fields=["uploaded_at"], name="samples_apk_uploade_100eb5_idx"
+                    ),
+                ],
+            },
+        ),
+    ]
diff --git a/apps/samples/migrations/0002_apksample_is_valid_apk_apksample_updated_at_and_more.py b/apps/samples/migrations/0002_apksample_is_valid_apk_apksample_updated_at_and_more.py
new file mode 100644
index 0000000000000000000000000000000000000000..b31977b598f9ae434c7dd205feb47c7432aeecf2
--- /dev/null
+++ b/apps/samples/migrations/0002_apksample_is_valid_apk_apksample_updated_at_and_more.py
@@ -0,0 +1,28 @@
+# Generated by Django 5.1.6 on 2026-04-03 08:27
+
+from django.db import migrations, models
+
+
+class Migration(migrations.Migration):
+
+    dependencies = [
+        ("samples", "0001_initial"),
+    ]
+
+    operations = [
+        migrations.AddField(
+            model_name="apksample",
+            name="is_valid_apk",
+            field=models.BooleanField(default=False),
+        ),
+        migrations.AddField(
+            model_name="apksample",
+            name="updated_at",
+            field=models.DateTimeField(auto_now=True),
+        ),
+        migrations.AddField(
+            model_name="apksample",
+            name="validation_errors",
+            field=models.TextField(blank=True, default=""),
+        ),
+    ]
diff --git a/apps/samples/migrations/__init__.py b/apps/samples/migrations/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/samples/models.py b/apps/samples/models.py
new file mode 100644
index 0000000000000000000000000000000000000000..a15b2892c27ff1213e3fc63b0a9fc33214d809ba
--- /dev/null
+++ b/apps/samples/models.py
@@ -0,0 +1,32 @@
+from django.db import models
+
+
+class APKSample(models.Model):
+    file = models.FileField(upload_to='apks/%Y/%m/%d/')
+    file_name = models.CharField(max_length=255)
+    file_size = models.BigIntegerField(default=0)
+    mime_type = models.CharField(max_length=128, blank=True, default='')
+    sha256 = models.CharField(max_length=64, unique=True)
+
+    package_name = models.CharField(max_length=255, blank=True, default='')
+    version_name = models.CharField(max_length=128, blank=True, default='')
+    version_code = models.CharField(max_length=64, blank=True, default='')
+
+    is_valid_apk = models.BooleanField(default=False)
+    validation_errors = models.TextField(blank=True, default='')
+
+    uploaded_at = models.DateTimeField(auto_now_add=True)
+    updated_at = models.DateTimeField(auto_now=True)
+
+    meta_json = models.JSONField(default=dict, blank=True)
+
+    class Meta:
+        ordering = ['-uploaded_at']
+        indexes = [
+            models.Index(fields=['sha256']),
+            models.Index(fields=['package_name']),
+            models.Index(fields=['uploaded_at']),
+        ]
+
+    def __str__(self) -> str:
+        return f'{self.file_name} ({self.sha256[:10]})'
diff --git a/apps/samples/services.py b/apps/samples/services.py
new file mode 100644
index 0000000000000000000000000000000000000000..73a4a0a42a7f9657561916f1649782a5205cb63f
--- /dev/null
+++ b/apps/samples/services.py
@@ -0,0 +1,99 @@
+import hashlib
+import zipfile
+from pathlib import Path
+
+from apkutils2 import APK
+from django.core.exceptions import ValidationError
+
+from apps.samples.models import APKSample
+
+ALLOWED_MIME_TYPES = {
+    'application/vnd.android.package-archive',
+    'application/zip',
+    'application/octet-stream',
+}
+
+
+def calc_sha256(uploaded_file) -> str:
+    hasher = hashlib.sha256()
+    for chunk in uploaded_file.chunks():
+        hasher.update(chunk)
+    uploaded_file.seek(0)
+    return hasher.hexdigest()
+
+
+def validate_apk_upload(uploaded_file) -> None:
+    if not uploaded_file.name.lower().endswith('.apk'):
+        raise ValidationError('文件扩展名不合法，必须为 .apk')
+
+    content_type = getattr(uploaded_file, 'content_type', '') or ''
+    if content_type and content_type not in ALLOWED_MIME_TYPES:
+        raise ValidationError(f'文件 MIME 类型不合法: {content_type}')
+
+    header = uploaded_file.read(4)
+    uploaded_file.seek(0)
+    if header[:2] != b'PK':
+        raise ValidationError('APK 文件头校验失败，非 ZIP/APK 文件')
+
+    try:
+        with zipfile.ZipFile(uploaded_file) as archive:
+            names = set(archive.namelist())
+            if 'AndroidManifest.xml' not in names:
+                raise ValidationError('APK 文件缺少 AndroidManifest.xml')
+    except zipfile.BadZipFile as exc:
+        raise ValidationError('APK 压缩结构无效') from exc
+    finally:
+        uploaded_file.seek(0)
+
+
+def extract_apk_meta(file_path: Path) -> dict:
+    meta = {
+        'package_name': '',
+        'version_name': '',
+        'version_code': '',
+        'manifest': {},
+    }
+    try:
+        apk = APK.from_file(str(file_path))
+        manifest = apk.manifest_data or {}
+        meta['manifest'] = manifest
+        meta['package_name'] = manifest.get('@package', '')
+        meta['version_name'] = manifest.get('@android:versionName', '')
+        meta['version_code'] = str(manifest.get('@android:versionCode', ''))
+    except Exception as exc:  # noqa: BLE001
+        meta['parse_error'] = str(exc)
+    return meta
+
+
+def create_or_get_sample(uploaded_file) -> tuple[APKSample, bool]:
+    validate_apk_upload(uploaded_file)
+    sha256 = calc_sha256(uploaded_file)
+
+    existing = APKSample.objects.filter(sha256=sha256).first()
+    if existing:
+        return existing, False
+
+    sample = APKSample.objects.create(
+        file=uploaded_file,
+        file_name=uploaded_file.name,
+        file_size=uploaded_file.size,
+        mime_type=getattr(uploaded_file, 'content_type', '') or '',
+        sha256=sha256,
+        is_valid_apk=True,
+    )
+
+    meta = extract_apk_meta(Path(sample.file.path))
+    sample.package_name = meta.get('package_name', '')
+    sample.version_name = meta.get('version_name', '')
+    sample.version_code = meta.get('version_code', '')
+    sample.meta_json = meta
+    sample.save(
+        update_fields=['package_name', 'version_name', 'version_code', 'meta_json', 'updated_at']
+    )
+    return sample, True
+
+
+
+def validate_apk_file(uploaded_file) -> None:
+    """Backward-compatible alias for old analysis flow."""
+    validate_apk_upload(uploaded_file)
diff --git a/apps/samples/urls.py b/apps/samples/urls.py
new file mode 100644
index 0000000000000000000000000000000000000000..8f599e517a76590950f054f8aafdb825f1e0b32c
--- /dev/null
+++ b/apps/samples/urls.py
@@ -0,0 +1,10 @@
+from django.urls import path
+
+from apps.samples import views
+
+app_name = 'samples'
+
+urlpatterns = [
+    path('upload/', views.upload_apk, name='upload_apk'),
+    path('<int:sample_id>/', views.sample_detail, name='sample_detail'),
+]
diff --git a/apps/samples/views.py b/apps/samples/views.py
new file mode 100644
index 0000000000000000000000000000000000000000..684e4da22edb2cd038644856d16b51374a7939ff
--- /dev/null
+++ b/apps/samples/views.py
@@ -0,0 +1,48 @@
+from django.contrib import messages
+from django.core.exceptions import ValidationError
+from django.shortcuts import get_object_or_404, redirect, render
+
+from apps.samples.forms import APKUploadForm
+from apps.samples.models import APKSample
+from apps.samples.services import create_or_get_sample
+from apps.shell_detector.services import detect_shell_and_strategy
+
+
+def upload_apk(request):
+    if request.method == 'POST':
+        form = APKUploadForm(request.POST, request.FILES)
+        if form.is_valid():
+            apk_file = form.cleaned_data['file']
+            try:
+                sample, created = create_or_get_sample(apk_file)
+            except ValidationError as exc:
+                form.add_error('file', str(exc))
+                return render(request, 'samples/upload.html', {'form': form})
+
+            detection = detect_shell_and_strategy(sample)
+            if created:
+                messages.success(request, 'APK 上传成功并完成识壳。')
+            else:
+                messages.info(request, '样本已存在，已返回历史记录并刷新识壳结果。')
+
+            if detection.strategy == 'MANUAL_REVIEW':
+                messages.warning(request, '检测到未知/复杂壳，建议人工复核。')
+
+            return redirect('samples:sample_detail', sample_id=sample.id)
+    else:
+        form = APKUploadForm()
+
+    return render(request, 'samples/upload.html', {'form': form})
+
+
+def sample_detail(request, sample_id: int):
+    sample = get_object_or_404(APKSample, id=sample_id)
+    latest_detection = sample.shell_detections.order_by('-created_at').first()
+    return render(
+        request,
+        'samples/detail.html',
+        {
+            'sample': sample,
+            'detection': latest_detection,
+        },
+    )
diff --git a/apps/shell_detector/__init__.py b/apps/shell_detector/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/shell_detector/admin.py b/apps/shell_detector/admin.py
new file mode 100644
index 0000000000000000000000000000000000000000..bb0c702bc2367e676e919634414f9c61e913e4cb
--- /dev/null
+++ b/apps/shell_detector/admin.py
@@ -0,0 +1,19 @@
+from django.contrib import admin
+
+from apps.shell_detector.models import ShellDetectionResult
+
+
+@admin.register(ShellDetectionResult)
+class ShellDetectionResultAdmin(admin.ModelAdmin):
+    list_display = (
+        'id',
+        'sample',
+        'shell_type',
+        'confidence',
+        'strategy',
+        'exit_code',
+        'created_at',
+    )
+    list_filter = ('shell_type', 'strategy', 'created_at')
+    search_fields = ('sample__file_name', 'sample__sha256', 'shell_type', 'evidence')
+    readonly_fields = ('created_at', 'updated_at')
diff --git a/apps/shell_detector/apps.py b/apps/shell_detector/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..a2af11cf5a20ae1d319e70bc6161d3557ae3f72b
--- /dev/null
+++ b/apps/shell_detector/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class ShellDetectorConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'apps.shell_detector'
+    verbose_name = '壳识别'
diff --git a/apps/shell_detector/migrations/0001_initial.py b/apps/shell_detector/migrations/0001_initial.py
new file mode 100644
index 0000000000000000000000000000000000000000..97c8411b925cab9169cf26b1a9ec095c5e1b570b
--- /dev/null
+++ b/apps/shell_detector/migrations/0001_initial.py
@@ -0,0 +1,78 @@
+# Generated by Django 5.1.6 on 2026-04-03 08:27
+
+import django.db.models.deletion
+from django.db import migrations, models
+
+
+class Migration(migrations.Migration):
+
+    initial = True
+
+    dependencies = [
+        ("samples", "0002_apksample_is_valid_apk_apksample_updated_at_and_more"),
+    ]
+
+    operations = [
+        migrations.CreateModel(
+            name="ShellDetectionResult",
+            fields=[
+                (
+                    "id",
+                    models.BigAutoField(
+                        auto_created=True,
+                        primary_key=True,
+                        serialize=False,
+                        verbose_name="ID",
+                    ),
+                ),
+                (
+                    "shell_type",
+                    models.CharField(blank=True, default="UNKNOWN", max_length=128),
+                ),
+                ("confidence", models.FloatField(default=0.0)),
+                ("evidence", models.TextField(blank=True, default="")),
+                (
+                    "strategy",
+                    models.CharField(
+                        choices=[
+                            ("NO_UNPACK", "无需脱壳"),
+                            ("BLACKDEX", "BlackDex"),
+                            ("FRIDA", "Frida"),
+                            ("BLACKDEX_THEN_FRIDA", "BlackDex 后 Frida"),
+                            ("MANUAL_REVIEW", "人工复核"),
+                        ],
+                        default="BLACKDEX_THEN_FRIDA",
+                        max_length=32,
+                    ),
+                ),
+                ("raw_output", models.JSONField(blank=True, default=dict)),
+                ("command", models.CharField(blank=True, default="", max_length=255)),
+                ("exit_code", models.IntegerField(blank=True, null=True)),
+                ("error_message", models.TextField(blank=True, default="")),
+                ("created_at", models.DateTimeField(auto_now_add=True)),
+                ("updated_at", models.DateTimeField(auto_now=True)),
+                (
+                    "sample",
+                    models.ForeignKey(
+                        on_delete=django.db.models.deletion.CASCADE,
+                        related_name="shell_detections",
+                        to="samples.apksample",
+                    ),
+                ),
+            ],
+            options={
+                "ordering": ["-created_at"],
+                "indexes": [
+                    models.Index(
+                        fields=["shell_type"], name="shell_detec_shell_t_378ad1_idx"
+                    ),
+                    models.Index(
+                        fields=["strategy"], name="shell_detec_strateg_1b0304_idx"
+                    ),
+                    models.Index(
+                        fields=["created_at"], name="shell_detec_created_1faea7_idx"
+                    ),
+                ],
+            },
+        ),
+    ]
diff --git a/apps/shell_detector/migrations/__init__.py b/apps/shell_detector/migrations/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/shell_detector/models.py b/apps/shell_detector/models.py
new file mode 100644
index 0000000000000000000000000000000000000000..25907bfe269925b5e01f53eb8c84c7b8da3a011f
--- /dev/null
+++ b/apps/shell_detector/models.py
@@ -0,0 +1,44 @@
+from django.db import models
+
+from apps.samples.models import APKSample
+
+
+class UnpackStrategy(models.TextChoices):
+    NO_UNPACK = 'NO_UNPACK', '无需脱壳'
+    BLACKDEX = 'BLACKDEX', 'BlackDex'
+    FRIDA = 'FRIDA', 'Frida'
+    BLACKDEX_THEN_FRIDA = 'BLACKDEX_THEN_FRIDA', 'BlackDex 后 Frida'
+    MANUAL_REVIEW = 'MANUAL_REVIEW', '人工复核'
+
+
+class ShellDetectionResult(models.Model):
+    sample = models.ForeignKey(APKSample, on_delete=models.CASCADE, related_name='shell_detections')
+
+    shell_type = models.CharField(max_length=128, blank=True, default='UNKNOWN')
+    confidence = models.FloatField(default=0.0)
+    evidence = models.TextField(blank=True, default='')
+
+    strategy = models.CharField(
+        max_length=32,
+        choices=UnpackStrategy.choices,
+        default=UnpackStrategy.BLACKDEX_THEN_FRIDA,
+    )
+
+    raw_output = models.JSONField(default=dict, blank=True)
+    command = models.CharField(max_length=255, blank=True, default='')
+    exit_code = models.IntegerField(null=True, blank=True)
+    error_message = models.TextField(blank=True, default='')
+
+    created_at = models.DateTimeField(auto_now_add=True)
+    updated_at = models.DateTimeField(auto_now=True)
+
+    class Meta:
+        ordering = ['-created_at']
+        indexes = [
+            models.Index(fields=['shell_type']),
+            models.Index(fields=['strategy']),
+            models.Index(fields=['created_at']),
+        ]
+
+    def __str__(self) -> str:
+        return f'ShellDetection(sample={self.sample_id}, shell={self.shell_type}, strategy={self.strategy})'
diff --git a/apps/shell_detector/services.py b/apps/shell_detector/services.py
new file mode 100644
index 0000000000000000000000000000000000000000..a00105be3df43488f528c4f39d07bed41c7f6fee
--- /dev/null
+++ b/apps/shell_detector/services.py
@@ -0,0 +1,145 @@
+import json
+import subprocess
+from dataclasses import dataclass
+
+from django.conf import settings
+
+from apps.samples.models import APKSample
+from apps.shell_detector.models import ShellDetectionResult
+from apps.shell_detector.strategy_selector import select_unpack_strategy
+
+
+@dataclass
+class NormalizedAPKiDResult:
+    shell_type: str
+    confidence: float
+    evidence: str
+    raw_output: dict
+    command: str
+    exit_code: int | None
+    error_message: str
+
+
+def _parse_shell_type(apkid_json: dict) -> tuple[str, str]:
+    files = apkid_json.get('files', [])
+    if not files:
+        return 'UNKNOWN', 'APKiD 未返回 files 字段'
+
+    first = files[0]
+    matches = first.get('matches', {})
+    for category, tags in matches.items():
+        tags = tags if isinstance(tags, list) else [str(tags)]
+        lowered = ' '.join(tags).lower()
+        if '360' in lowered or 'qihoo' in lowered:
+            return 'JIAGU_360', f'{category}: {tags}'
+        if 'bangcle' in lowered:
+            return 'BANGCLE', f'{category}: {tags}'
+        if 'ijiami' in lowered:
+            return 'IJIAMI', f'{category}: {tags}'
+        if 'legu' in lowered or 'tencent' in lowered:
+            return 'TENCENT_LEGU', f'{category}: {tags}'
+
+    if matches:
+        return 'UNKNOWN', str(matches)
+
+    return 'NONE', '未识别到壳特征'
+
+
+def run_apkid(file_path: str, timeout: int = 120) -> NormalizedAPKiDResult:
+    base_cmd = getattr(settings, 'APKiD_COMMAND', ['apkid', '-j'])
+    cmd = [*base_cmd, file_path]
+    command_str = ' '.join(cmd)
+
+    try:
+        proc = subprocess.run(
+            cmd,
+            capture_output=True,
+            text=True,
+            timeout=timeout,
+            check=False,
+        )
+    except subprocess.TimeoutExpired as exc:
+        return NormalizedAPKiDResult(
+            shell_type='UNKNOWN',
+            confidence=0.0,
+            evidence='APKiD 执行超时',
+            raw_output={'stdout': exc.stdout, 'stderr': exc.stderr},
+            command=command_str,
+            exit_code=None,
+            error_message='timeout',
+        )
+    except FileNotFoundError:
+        return NormalizedAPKiDResult(
+            shell_type='UNKNOWN',
+            confidence=0.0,
+            evidence='未找到 apkid 命令，请检查环境安装',
+            raw_output={},
+            command=command_str,
+            exit_code=None,
+            error_message='apkid_not_found',
+        )
+    except OSError as exc:
+        return NormalizedAPKiDResult(
+            shell_type='UNKNOWN',
+            confidence=0.0,
+            evidence='系统无法启动 APKiD',
+            raw_output={},
+            command=command_str,
+            exit_code=None,
+            error_message=str(exc),
+        )
+
+    if proc.returncode != 0:
+        return NormalizedAPKiDResult(
+            shell_type='UNKNOWN',
+            confidence=0.0,
+            evidence='APKiD 返回非零退出码',
+            raw_output={'stdout': proc.stdout, 'stderr': proc.stderr},
+            command=command_str,
+            exit_code=proc.returncode,
+            error_message=proc.stderr.strip(),
+        )
+
+    try:
+        parsed = json.loads(proc.stdout or '{}')
+    except json.JSONDecodeError:
+        parsed = {'stdout': proc.stdout, 'stderr': proc.stderr, 'parse_error': True}
+        return NormalizedAPKiDResult(
+            shell_type='UNKNOWN',
+            confidence=0.0,
+            evidence='APKiD 输出不是合法 JSON',
+            raw_output=parsed,
+            command=command_str,
+            exit_code=proc.returncode,
+            error_message='invalid_json',
+        )
+
+    shell_type, evidence = _parse_shell_type(parsed)
+    strategy, confidence = select_unpack_strategy(shell_type)
+    normalized_confidence = min(max(confidence, 0.0), 1.0)
+
+    return NormalizedAPKiDResult(
+        shell_type=shell_type,
+        confidence=normalized_confidence,
+        evidence=f'{evidence}; strategy={strategy}',
+        raw_output=parsed,
+        command=command_str,
+        exit_code=proc.returncode,
+        error_message='',
+    )
+
+
+def detect_shell_and_strategy(sample: APKSample) -> ShellDetectionResult:
+    result = run_apkid(sample.file.path)
+    strategy, _ = select_unpack_strategy(result.shell_type)
+    return ShellDetectionResult.objects.create(
+        sample=sample,
+        shell_type=result.shell_type,
+        confidence=result.confidence,
+        evidence=result.evidence,
+        strategy=strategy,
+        raw_output=result.raw_output,
+        command=result.command,
+        exit_code=result.exit_code,
+        error_message=result.error_message,
+    )
diff --git a/apps/shell_detector/strategy_selector.py b/apps/shell_detector/strategy_selector.py
new file mode 100644
index 0000000000000000000000000000000000000000..2c2738c0d99a50f1388179188ef3f5bca3cb070d
--- /dev/null
+++ b/apps/shell_detector/strategy_selector.py
@@ -0,0 +1,21 @@
+from apps.shell_detector.models import UnpackStrategy
+
+
+SHELL_STRATEGY_MAP = {
+    'JIAGU_360': (UnpackStrategy.FRIDA, 0.92),
+    'BANGCLE': (UnpackStrategy.BLACKDEX, 0.88),
+    'IJIAMI': (UnpackStrategy.BLACKDEX, 0.86),
+    'TENCENT_LEGU': (UnpackStrategy.BLACKDEX_THEN_FRIDA, 0.80),
+    'NONE': (UnpackStrategy.NO_UNPACK, 0.95),
+}
+
+
+def select_unpack_strategy(shell_type: str) -> tuple[str, float]:
+    normalized = (shell_type or 'UNKNOWN').upper()
+    if normalized in SHELL_STRATEGY_MAP:
+        return SHELL_STRATEGY_MAP[normalized]
+
+    if 'UNKNOWN' in normalized:
+        return UnpackStrategy.MANUAL_REVIEW, 0.30
+
+    return UnpackStrategy.BLACKDEX_THEN_FRIDA, 0.55
diff --git a/apps/task_ops/__init__.py b/apps/task_ops/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/task_ops/admin.py b/apps/task_ops/admin.py
new file mode 100644
index 0000000000000000000000000000000000000000..0e8d9c8f8c7c4e4013d389a8998b32ae3399e3bd
--- /dev/null
+++ b/apps/task_ops/admin.py
@@ -0,0 +1,37 @@
+from django.contrib import admin
+from django.contrib.admin.sites import AlreadyRegistered
+
+from apps.unpack_tasks.models import TaskExecutionLog, UnpackJob
+
+
+class TaskOpsUnpackJobAdmin(admin.ModelAdmin):
+    list_display = (
+        'id',
+        'sample',
+        'status',
+        'strategy',
+        'retry_count',
+        'requires_review',
+        'started_at',
+        'finished_at',
+    )
+    list_filter = ('status', 'strategy', 'requires_review')
+    search_fields = ('sample__file_name', 'sample__sha256', 'error_message')
+    readonly_fields = ('created_at', 'updated_at', 'started_at', 'finished_at')
+
+
+class TaskOpsExecutionLogAdmin(admin.ModelAdmin):
+    list_display = ('id', 'job', 'stage', 'level', 'created_at')
+    list_filter = ('level', 'stage', 'created_at')
+    search_fields = ('job__sample__file_name', 'message')
+
+
+try:
+    admin.site.register(UnpackJob, TaskOpsUnpackJobAdmin)
+except AlreadyRegistered:
+    pass
+
+try:
+    admin.site.register(TaskExecutionLog, TaskOpsExecutionLogAdmin)
+except AlreadyRegistered:
+    pass
diff --git a/apps/task_ops/apps.py b/apps/task_ops/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..3f57284484c3ed23f70dd8a7c664cd866597e0c7
--- /dev/null
+++ b/apps/task_ops/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class TaskOpsConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'apps.task_ops'
+    verbose_name = '任务运维'
diff --git a/apps/task_ops/urls.py b/apps/task_ops/urls.py
new file mode 100644
index 0000000000000000000000000000000000000000..5774e021c1b60c2dd2566d99c6e646d3a715b92a
--- /dev/null
+++ b/apps/task_ops/urls.py
@@ -0,0 +1,11 @@
+from django.urls import path
+
+from apps.task_ops import views
+
+app_name = 'task_ops'
+
+urlpatterns = [
+    path('tasks/', views.task_list, name='task_list'),
+    path('tasks/<int:job_id>/', views.task_detail, name='task_detail'),
+    path('tasks/<int:job_id>/logs/', views.task_logs, name='task_logs'),
+]
diff --git a/apps/task_ops/views.py b/apps/task_ops/views.py
new file mode 100644
index 0000000000000000000000000000000000000000..324168542e962a1f51f374ef518c84a30073edaa
--- /dev/null
+++ b/apps/task_ops/views.py
@@ -0,0 +1,136 @@
+from datetime import timedelta
+
+from django.core.paginator import Paginator
+from django.db.models import Count, Q
+from django.shortcuts import get_object_or_404, render
+from django.utils import timezone
+
+from apps.unpack_tasks.models import TaskExecutionLog, TaskStatus, UnpackJob
+
+
+def task_list(request):
+    status = request.GET.get('status', '').strip()
+    shell_type = request.GET.get('shell_type', '').strip()
+    strategy = request.GET.get('strategy', '').strip()
+    user = request.GET.get('user', '').strip()
+
+    qs = UnpackJob.objects.select_related('sample', 'shell_detection').all()
+
+    if status:
+        qs = qs.filter(status=status)
+    if shell_type:
+        qs = qs.filter(shell_detection__shell_type__icontains=shell_type)
+    if strategy:
+        qs = qs.filter(strategy=strategy)
+    if user:
+        qs = qs.filter(
+            Q(sample__meta_json__uploader__icontains=user)
+            | Q(sample__meta_json__uploaded_by__icontains=user)
+        )
+
+    paginator = Paginator(qs, 20)
+    page_obj = paginator.get_page(request.GET.get('page'))
+
+    status_stats = UnpackJob.objects.values('status').annotate(total=Count('id')).order_by('status')
+    shell_stats = (
+        UnpackJob.objects.values('shell_detection__shell_type')
+        .annotate(total=Count('id'))
+        .order_by('-total')[:10]
+    )
+
+    context = {
+        'page_obj': page_obj,
+        'status_choices': TaskStatus.choices,
+        'strategy_choices': UnpackJob._meta.get_field('strategy').choices,
+        'filters': {
+            'status': status,
+            'shell_type': shell_type,
+            'strategy': strategy,
+            'user': user,
+        },
+        'status_stats': status_stats,
+        'shell_stats': shell_stats,
+    }
+    return render(request, 'task_ops/task_list.html', context)
+
+
+def task_detail(request, job_id: int):
+    job = get_object_or_404(
+        UnpackJob.objects.select_related('sample', 'shell_detection'),
+        id=job_id,
+    )
+
+    logs = TaskExecutionLog.objects.filter(job=job).order_by('created_at')
+    timeline = _build_timeline(job, logs)
+    total_duration = _get_total_duration(job)
+
+    context = {
+        'job': job,
+        'timeline': timeline,
+        'total_duration': total_duration,
+        'recent_logs': logs.order_by('-created_at')[:20],
+    }
+    return render(request, 'task_ops/task_detail.html', context)
+
+
+def task_logs(request, job_id: int):
+    job = get_object_or_404(UnpackJob, id=job_id)
+    logs = TaskExecutionLog.objects.filter(job=job).order_by('-created_at')
+
+    level = request.GET.get('level', '').strip()
+    stage = request.GET.get('stage', '').strip()
+
+    if level:
+        logs = logs.filter(level=level)
+    if stage:
+        logs = logs.filter(stage=stage)
+
+    paginator = Paginator(logs, 50)
+    page_obj = paginator.get_page(request.GET.get('page'))
+
+    context = {
+        'job': job,
+        'page_obj': page_obj,
+        'level': level,
+        'stage': stage,
+        'level_choices': ['INFO', 'WARNING', 'ERROR'],
+    }
+    return render(request, 'task_ops/task_logs.html', context)
+
+
+def _build_timeline(job: UnpackJob, logs):
+    timeline = []
+    last_time = job.started_at or job.created_at
+    for log in logs:
+        elapsed = None
+        if last_time:
+            elapsed_delta = log.created_at - last_time
+            elapsed = _format_duration(elapsed_delta)
+        timeline.append(
+            {
+                'time': log.created_at,
+                'stage': log.stage,
+                'level': log.level,
+                'message': log.message,
+                'elapsed_since_previous': elapsed,
+            }
+        )
+        last_time = log.created_at
+    return timeline
+
+
+def _get_total_duration(job: UnpackJob) -> str:
+    if not job.started_at:
+        return '-'
+    end = job.finished_at or timezone.now()
+    delta = end - job.started_at
+    return _format_duration(delta)
+
+
+def _format_duration(delta: timedelta) -> str:
+    total_seconds = int(delta.total_seconds())
+    if total_seconds < 0:
+        total_seconds = 0
+    minutes, seconds = divmod(total_seconds, 60)
+    hours, minutes = divmod(minutes, 60)
+    return f'{hours:02d}:{minutes:02d}:{seconds:02d}'
diff --git a/apps/unpack_tasks/__init__.py b/apps/unpack_tasks/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/unpack_tasks/admin.py b/apps/unpack_tasks/admin.py
new file mode 100644
index 0000000000000000000000000000000000000000..b119fbe1a83a19a204a62b973c37bc76e0d2b207
--- /dev/null
+++ b/apps/unpack_tasks/admin.py
@@ -0,0 +1,43 @@
+from django.contrib import admin
+from django.contrib.admin.sites import AlreadyRegistered
+
+from apps.unpack_tasks.models import TaskExecutionLog, UnpackJob
+
+
+class TaskExecutionLogInline(admin.TabularInline):
+    model = TaskExecutionLog
+    extra = 0
+    readonly_fields = ('stage', 'level', 'message', 'data', 'created_at')
+
+
+class UnpackJobAdmin(admin.ModelAdmin):
+    list_display = (
+        'id',
+        'sample',
+        'status',
+        'strategy',
+        'retry_count',
+        'requires_review',
+        'created_at',
+    )
+    list_filter = ('status', 'strategy', 'requires_review', 'created_at')
+    search_fields = ('sample__file_name', 'sample__sha256', 'celery_task_id')
+    readonly_fields = ('created_at', 'updated_at', 'started_at', 'finished_at')
+    inlines = [TaskExecutionLogInline]
+
+
+class TaskExecutionLogAdmin(admin.ModelAdmin):
+    list_display = ('id', 'job', 'stage', 'level', 'created_at')
+    list_filter = ('level', 'stage', 'created_at')
+    search_fields = ('job__sample__file_name', 'message')
+
+
+try:
+    admin.site.register(UnpackJob, UnpackJobAdmin)
+except AlreadyRegistered:
+    pass
+
+try:
+    admin.site.register(TaskExecutionLog, TaskExecutionLogAdmin)
+except AlreadyRegistered:
+    pass
diff --git a/apps/unpack_tasks/apps.py b/apps/unpack_tasks/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..4da921762fb975fe8adbf875f26e8d6ea87d3bd0
--- /dev/null
+++ b/apps/unpack_tasks/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class UnpackTasksConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'apps.unpack_tasks'
+    verbose_name = '异步脱壳任务'
diff --git a/apps/unpack_tasks/migrations/0001_initial.py b/apps/unpack_tasks/migrations/0001_initial.py
new file mode 100644
index 0000000000000000000000000000000000000000..360c61f3f4cc6ea1f5d1bc703aca6cc4cd4c5e98
--- /dev/null
+++ b/apps/unpack_tasks/migrations/0001_initial.py
@@ -0,0 +1,166 @@
+# Generated by Django 5.1.6 on 2026-04-03 08:36
+
+import django.db.models.deletion
+from django.db import migrations, models
+
+
+class Migration(migrations.Migration):
+
+    initial = True
+
+    dependencies = [
+        ("samples", "0002_apksample_is_valid_apk_apksample_updated_at_and_more"),
+        ("shell_detector", "0001_initial"),
+    ]
+
+    operations = [
+        migrations.CreateModel(
+            name="UnpackJob",
+            fields=[
+                (
+                    "id",
+                    models.BigAutoField(
+                        auto_created=True,
+                        primary_key=True,
+                        serialize=False,
+                        verbose_name="ID",
+                    ),
+                ),
+                (
+                    "status",
+                    models.CharField(
+                        choices=[
+                            ("PENDING", "待处理"),
+                            ("QUEUED", "已入队"),
+                            ("IDENTIFYING_SHELL", "识壳中"),
+                            ("SELECTING_STRATEGY", "选择策略"),
+                            ("STARTING_EMULATOR", "启动模拟器"),
+                            ("INSTALLING_APK", "安装APK"),
+                            ("RUNNING_BLACKDEX", "运行BlackDex"),
+                            ("RUNNING_FRIDA", "运行Frida"),
+                            ("COLLECTING_ARTIFACTS", "收集产物"),
+                            ("SUCCESS", "成功"),
+                            ("PARTIAL_SUCCESS", "部分成功"),
+                            ("FAILED", "失败"),
+                            ("REVIEW_REQUIRED", "人工复核"),
+                        ],
+                        default="PENDING",
+                        max_length=32,
+                    ),
+                ),
+                (
+                    "strategy",
+                    models.CharField(
+                        choices=[
+                            ("NO_UNPACK", "无需脱壳"),
+                            ("BLACKDEX", "BlackDex"),
+                            ("FRIDA", "Frida"),
+                            ("BLACKDEX_THEN_FRIDA", "BlackDex 后 Frida"),
+                            ("MANUAL_REVIEW", "人工复核"),
+                        ],
+                        default="BLACKDEX_THEN_FRIDA",
+                        max_length=32,
+                    ),
+                ),
+                ("retry_count", models.PositiveIntegerField(default=0)),
+                ("max_retries", models.PositiveIntegerField(default=3)),
+                (
+                    "celery_task_id",
+                    models.CharField(blank=True, default="", max_length=64),
+                ),
+                (
+                    "artifact_dir",
+                    models.CharField(blank=True, default="", max_length=512),
+                ),
+                ("artifact_paths", models.JSONField(blank=True, default=list)),
+                ("result_summary", models.JSONField(blank=True, default=dict)),
+                ("error_message", models.TextField(blank=True, default="")),
+                ("requires_review", models.BooleanField(default=False)),
+                ("started_at", models.DateTimeField(blank=True, null=True)),
+                ("finished_at", models.DateTimeField(blank=True, null=True)),
+                ("created_at", models.DateTimeField(auto_now_add=True)),
+                ("updated_at", models.DateTimeField(auto_now=True)),
+                (
+                    "sample",
+                    models.ForeignKey(
+                        on_delete=django.db.models.deletion.CASCADE,
+                        related_name="unpack_jobs",
+                        to="samples.apksample",
+                    ),
+                ),
+                (
+                    "shell_detection",
+                    models.ForeignKey(
+                        blank=True,
+                        null=True,
+                        on_delete=django.db.models.deletion.SET_NULL,
+                        related_name="unpack_jobs",
+                        to="shell_detector.shelldetectionresult",
+                    ),
+                ),
+            ],
+            options={
+                "ordering": ["-created_at"],
+            },
+        ),
+        migrations.CreateModel(
+            name="TaskExecutionLog",
+            fields=[
+                (
+                    "id",
+                    models.BigAutoField(
+                        auto_created=True,
+                        primary_key=True,
+                        serialize=False,
+                        verbose_name="ID",
+                    ),
+                ),
+                ("stage", models.CharField(max_length=64)),
+                ("level", models.CharField(default="INFO", max_length=16)),
+                ("message", models.TextField()),
+                ("data", models.JSONField(blank=True, default=dict)),
+                ("created_at", models.DateTimeField(auto_now_add=True)),
+                (
+                    "job",
+                    models.ForeignKey(
+                        on_delete=django.db.models.deletion.CASCADE,
+                        related_name="logs",
+                        to="unpack_tasks.unpackjob",
+                    ),
+                ),
+            ],
+            options={
+                "ordering": ["created_at"],
+            },
+        ),
+        migrations.AddIndex(
+            model_name="unpackjob",
+            index=models.Index(fields=["status"], name="unpack_task_status_528ecb_idx"),
+        ),
+        migrations.AddIndex(
+            model_name="unpackjob",
+            index=models.Index(
+                fields=["strategy"], name="unpack_task_strateg_f7a56f_idx"
+            ),
+        ),
+        migrations.AddIndex(
+            model_name="unpackjob",
+            index=models.Index(
+                fields=["created_at"], name="unpack_task_created_8d28fc_idx"
+            ),
+        ),
+        migrations.AddIndex(
+            model_name="taskexecutionlog",
+            index=models.Index(fields=["stage"], name="unpack_task_stage_5ba23a_idx"),
+        ),
+        migrations.AddIndex(
+            model_name="taskexecutionlog",
+            index=models.Index(fields=["level"], name="unpack_task_level_3a1d8a_idx"),
+        ),
+        migrations.AddIndex(
+            model_name="taskexecutionlog",
+            index=models.Index(
+                fields=["created_at"], name="unpack_task_created_def2a2_idx"
+            ),
+        ),
+    ]
diff --git a/apps/unpack_tasks/migrations/__init__.py b/apps/unpack_tasks/migrations/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/apps/unpack_tasks/models.py b/apps/unpack_tasks/models.py
new file mode 100644
index 0000000000000000000000000000000000000000..a3daf5ad95e5f33826272ce4522686f9e916e1b5
--- /dev/null
+++ b/apps/unpack_tasks/models.py
@@ -0,0 +1,113 @@
+from django.db import models
+
+from apps.samples.models import APKSample
+from apps.shell_detector.models import ShellDetectionResult, UnpackStrategy
+
+
+class TaskStatus(models.TextChoices):
+    PENDING = 'PENDING', '待处理'
+    QUEUED = 'QUEUED', '已入队'
+    IDENTIFYING_SHELL = 'IDENTIFYING_SHELL', '识壳中'
+    SELECTING_STRATEGY = 'SELECTING_STRATEGY', '选择策略'
+    STARTING_EMULATOR = 'STARTING_EMULATOR', '启动模拟器'
+    INSTALLING_APK = 'INSTALLING_APK', '安装APK'
+    RUNNING_BLACKDEX = 'RUNNING_BLACKDEX', '运行BlackDex'
+    RUNNING_FRIDA = 'RUNNING_FRIDA', '运行Frida'
+    COLLECTING_ARTIFACTS = 'COLLECTING_ARTIFACTS', '收集产物'
+    SUCCESS = 'SUCCESS', '成功'
+    PARTIAL_SUCCESS = 'PARTIAL_SUCCESS', '部分成功'
+    FAILED = 'FAILED', '失败'
+    REVIEW_REQUIRED = 'REVIEW_REQUIRED', '人工复核'
+
+
+ALLOWED_TRANSITIONS: dict[str, set[str]] = {
+    TaskStatus.PENDING: {TaskStatus.QUEUED, TaskStatus.FAILED},
+    TaskStatus.QUEUED: {TaskStatus.IDENTIFYING_SHELL, TaskStatus.SELECTING_STRATEGY, TaskStatus.FAILED},
+    TaskStatus.IDENTIFYING_SHELL: {TaskStatus.SELECTING_STRATEGY, TaskStatus.REVIEW_REQUIRED, TaskStatus.FAILED},
+    TaskStatus.SELECTING_STRATEGY: {
+        TaskStatus.STARTING_EMULATOR,
+        TaskStatus.RUNNING_BLACKDEX,
+        TaskStatus.RUNNING_FRIDA,
+        TaskStatus.REVIEW_REQUIRED,
+        TaskStatus.SUCCESS,
+        TaskStatus.FAILED,
+    },
+    TaskStatus.STARTING_EMULATOR: {TaskStatus.INSTALLING_APK, TaskStatus.RUNNING_BLACKDEX, TaskStatus.RUNNING_FRIDA, TaskStatus.FAILED},
+    TaskStatus.INSTALLING_APK: {TaskStatus.RUNNING_BLACKDEX, TaskStatus.RUNNING_FRIDA, TaskStatus.FAILED},
+    TaskStatus.RUNNING_BLACKDEX: {TaskStatus.RUNNING_FRIDA, TaskStatus.COLLECTING_ARTIFACTS, TaskStatus.SUCCESS, TaskStatus.PARTIAL_SUCCESS, TaskStatus.FAILED},
+    TaskStatus.RUNNING_FRIDA: {TaskStatus.COLLECTING_ARTIFACTS, TaskStatus.SUCCESS, TaskStatus.PARTIAL_SUCCESS, TaskStatus.FAILED},
+    TaskStatus.COLLECTING_ARTIFACTS: {TaskStatus.SUCCESS, TaskStatus.PARTIAL_SUCCESS, TaskStatus.FAILED},
+    TaskStatus.SUCCESS: set(),
+    TaskStatus.PARTIAL_SUCCESS: {TaskStatus.REVIEW_REQUIRED},
+    TaskStatus.FAILED: {TaskStatus.QUEUED, TaskStatus.REVIEW_REQUIRED},
+    TaskStatus.REVIEW_REQUIRED: {TaskStatus.QUEUED, TaskStatus.SUCCESS, TaskStatus.FAILED},
+}
+
+
+class UnpackJob(models.Model):
+    sample = models.ForeignKey(APKSample, on_delete=models.CASCADE, related_name='unpack_jobs')
+    shell_detection = models.ForeignKey(
+        ShellDetectionResult,
+        null=True,
+        blank=True,
+        on_delete=models.SET_NULL,
+        related_name='unpack_jobs',
+    )
+
+    status = models.CharField(max_length=32, choices=TaskStatus.choices, default=TaskStatus.PENDING)
+    strategy = models.CharField(
+        max_length=32,
+        choices=UnpackStrategy.choices,
+        default=UnpackStrategy.BLACKDEX_THEN_FRIDA,
+    )
+
+    retry_count = models.PositiveIntegerField(default=0)
+    max_retries = models.PositiveIntegerField(default=3)
+
+    celery_task_id = models.CharField(max_length=64, blank=True, default='')
+
+    artifact_dir = models.CharField(max_length=512, blank=True, default='')
+    artifact_paths = models.JSONField(default=list, blank=True)
+    result_summary = models.JSONField(default=dict, blank=True)
+
+    error_message = models.TextField(blank=True, default='')
+    requires_review = models.BooleanField(default=False)
+
+    started_at = models.DateTimeField(null=True, blank=True)
+    finished_at = models.DateTimeField(null=True, blank=True)
+    created_at = models.DateTimeField(auto_now_add=True)
+    updated_at = models.DateTimeField(auto_now=True)
+
+    class Meta:
+        ordering = ['-created_at']
+        indexes = [
+            models.Index(fields=['status']),
+            models.Index(fields=['strategy']),
+            models.Index(fields=['created_at']),
+        ]
+
+    def __str__(self) -> str:
+        return f'UnpackJob#{self.id} sample={self.sample_id} status={self.status}'
+
+    def can_transition_to(self, new_status: str) -> bool:
+        return new_status in ALLOWED_TRANSITIONS.get(self.status, set())
+
+
+class TaskExecutionLog(models.Model):
+    job = models.ForeignKey(UnpackJob, on_delete=models.CASCADE, related_name='logs')
+    stage = models.CharField(max_length=64)
+    level = models.CharField(max_length=16, default='INFO')
+    message = models.TextField()
+    data = models.JSONField(default=dict, blank=True)
+    created_at = models.DateTimeField(auto_now_add=True)
+
+    class Meta:
+        ordering = ['created_at']
+        indexes = [
+            models.Index(fields=['stage']),
+            models.Index(fields=['level']),
+            models.Index(fields=['created_at']),
+        ]
+
+    def __str__(self) -> str:
+        return f'Log(job={self.job_id}, stage={self.stage}, level={self.level})'
diff --git a/apps/unpack_tasks/tasks.py b/apps/unpack_tasks/tasks.py
new file mode 100644
index 0000000000000000000000000000000000000000..17645cae85aebc3d7c6dd331ef5701c92992831f
--- /dev/null
+++ b/apps/unpack_tasks/tasks.py
@@ -0,0 +1,30 @@
+from celery import shared_task
+from django.db import transaction
+from django.utils import timezone
+
+from apps.execution.services import execute_unpack_flow
+from apps.unpack_tasks.models import TaskStatus, UnpackJob
+
+
+@shared_task(bind=True, autoretry_for=(RuntimeError,), retry_backoff=True, retry_kwargs={'max_retries': 3})
+def run_unpack_job(self, job_id: int) -> dict:
+    job = UnpackJob.objects.select_related('sample', 'shell_detection').get(id=job_id)
+    _queue_job(job, self.request.id)
+    result = execute_unpack_flow(job)
+    return result
+
+
+def enqueue_unpack_job(job: UnpackJob) -> UnpackJob:
+    task_result = run_unpack_job.delay(job.id)
+    _queue_job(job, task_result.id)
+    return job
+
+
+def _queue_job(job: UnpackJob, celery_task_id: str) -> None:
+    with transaction.atomic():
+        job = UnpackJob.objects.select_for_update().get(id=job.id)
+        if job.status == TaskStatus.PENDING:
+            job.status = TaskStatus.QUEUED
+            job.started_at = timezone.now()
+        job.celery_task_id = celery_task_id
+        job.save(update_fields=['status', 'started_at', 'celery_task_id', 'updated_at'])
diff --git a/config/__init__.py b/config/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..188aef26efccf65581b5e97991335b99be2b6b56
--- /dev/null
+++ b/config/__init__.py
@@ -0,0 +1,5 @@
+"""Django config package for android_unpack_platform."""
+
+from config.celery import app as celery_app
+
+__all__ = ('celery_app',)
diff --git a/config/asgi.py b/config/asgi.py
new file mode 100644
index 0000000000000000000000000000000000000000..5ef7b5a7c3c5c440f4bb747fbbe98bf96b2a4fcd
--- /dev/null
+++ b/config/asgi.py
@@ -0,0 +1,9 @@
+"""ASGI config for android_unpack_platform."""
+
+import os
+
+from django.core.asgi import get_asgi_application
+
+os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
+
+application = get_asgi_application()
diff --git a/config/celery.py b/config/celery.py
new file mode 100644
index 0000000000000000000000000000000000000000..af6f76e0f095f63c212d78d6b18c54a4c4cab18c
--- /dev/null
+++ b/config/celery.py
@@ -0,0 +1,17 @@
+"""Celery application bootstrap for android_unpack_platform."""
+
+import os
+
+from celery import Celery
+
+os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
+
+app = Celery('android_unpack_platform')
+app.config_from_object('django.conf:settings', namespace='CELERY')
+app.autodiscover_tasks()
+
+
+@app.task(bind=True)
+def debug_task(self):
+    """Simple debug task to verify worker setup."""
+    print(f'Request: {self.request!r}')
diff --git a/config/settings.py b/config/settings.py
new file mode 100644
index 0000000000000000000000000000000000000000..80586f45d1381b2483df6391ce8a437c1c22269e
--- /dev/null
+++ b/config/settings.py
@@ -0,0 +1,153 @@
+"""Core Django settings for android_unpack_platform."""
+
+from pathlib import Path
+
+BASE_DIR = Path(__file__).resolve().parent.parent
+
+# -----------------------------
+# Core settings
+# -----------------------------
+SECRET_KEY = 'replace-me-in-production'
+DEBUG = True
+ALLOWED_HOSTS = ['127.0.0.1', 'localhost']
+
+# -----------------------------
+# Application definition
+# -----------------------------
+INSTALLED_APPS = [
+    'django.contrib.admin',
+    'django.contrib.auth',
+    'django.contrib.contenttypes',
+    'django.contrib.sessions',
+    'django.contrib.messages',
+    'django.contrib.staticfiles',
+    # Business apps
+    'users',
+    'apps.task_ops',
+    'dashboard',
+    'apps.common',
+    'apps.samples',
+    'apps.shell_detector',
+    'apps.unpack_tasks',
+    'apps.execution',
+    'apps.analysis',
+    'apps.operations',
+]
+
+MIDDLEWARE = [
+    'django.middleware.security.SecurityMiddleware',
+    'django.contrib.sessions.middleware.SessionMiddleware',
+    'django.middleware.common.CommonMiddleware',
+    'django.middleware.csrf.CsrfViewMiddleware',
+    'django.contrib.auth.middleware.AuthenticationMiddleware',
+    'django.contrib.messages.middleware.MessageMiddleware',
+    'django.middleware.clickjacking.XFrameOptionsMiddleware',
+]
+
+ROOT_URLCONF = 'config.urls'
+
+TEMPLATES = [
+    {
+        'BACKEND': 'django.template.backends.django.DjangoTemplates',
+        'DIRS': [BASE_DIR / 'templates'],
+        'APP_DIRS': True,
+        'OPTIONS': {
+            'context_processors': [
+                'django.template.context_processors.request',
+                'django.contrib.auth.context_processors.auth',
+                'django.contrib.messages.context_processors.messages',
+            ],
+        },
+    },
+]
+
+WSGI_APPLICATION = 'config.wsgi.application'
+ASGI_APPLICATION = 'config.asgi.application'
+
+# -----------------------------
+# Database: PostgreSQL placeholder
+# -----------------------------
+DATABASES = {
+    'default': {
+        'ENGINE': 'django.db.backends.postgresql',
+        'NAME': 'android_unpack_platform',
+        'USER': 'postgres',
+        'PASSWORD': 'postgres',
+        'HOST': '127.0.0.1',
+        'PORT': '5432',
+    }
+}
+
+# -----------------------------
+# Password validation
+# -----------------------------
+AUTH_PASSWORD_VALIDATORS = [
+    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
+    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
+    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
+    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
+]
+
+# -----------------------------
+# i18n / timezone
+# -----------------------------
+LANGUAGE_CODE = 'zh-hans'
+TIME_ZONE = 'UTC'
+USE_I18N = True
+USE_TZ = True
+
+# -----------------------------
+# Static & Media
+# -----------------------------
+STATIC_URL = '/static/'
+STATIC_ROOT = BASE_DIR / 'staticfiles'
+
+MEDIA_URL = '/media/'
+MEDIA_ROOT = BASE_DIR / 'media'
+
+# -----------------------------
+# Project directories (separated)
+# -----------------------------
+UPLOAD_DIR = BASE_DIR / 'data' / 'uploads'
+LOG_DIR = BASE_DIR / 'data' / 'logs'
+ARTIFACT_DIR = BASE_DIR / 'data' / 'artifacts'
+
+for directory in (UPLOAD_DIR, LOG_DIR, ARTIFACT_DIR, MEDIA_ROOT):
+    directory.mkdir(parents=True, exist_ok=True)
+
+# -----------------------------
+# Redis placeholder
+# -----------------------------
+REDIS_HOST = '127.0.0.1'
+REDIS_PORT = 6379
+REDIS_DB = 0
+REDIS_URL = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'
+
+# -----------------------------
+# Celery settings
+# -----------------------------
+CELERY_BROKER_URL = REDIS_URL
+CELERY_RESULT_BACKEND = REDIS_URL
+CELERY_ACCEPT_CONTENT = ['json']
+CELERY_TASK_SERIALIZER = 'json'
+CELERY_RESULT_SERIALIZER = 'json'
+CELERY_TIMEZONE = TIME_ZONE
+CELERY_ENABLE_UTC = True
+CELERY_TASK_TRACK_STARTED = True
+CELERY_TASK_TIME_LIMIT = 20 * 60
+CELERY_TASK_SOFT_TIME_LIMIT = 15 * 60
+
+APKiD_COMMAND = ['apkid', '-j']
+APKiD_TIMEOUT = 120
+
+EMULATOR_START_COMMAND = ['echo', 'start_emulator']
+EMULATOR_STOP_COMMAND = ['echo', 'stop_emulator']
+EMULATOR_STATUS_COMMAND = ['echo', 'online']
+EMULATOR_INSTALL_APK_COMMAND = ['echo', 'install_apk']
+EMULATOR_TIMEOUT = 180
+BLACKDEX_COMMAND = ['echo', 'blackdex']
+BLACKDEX_TIMEOUT = 300
+FRIDA_COMMAND = ['echo', 'frida']
+FRIDA_TIMEOUT = 300
+
+DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
diff --git a/config/urls.py b/config/urls.py
new file mode 100644
index 0000000000000000000000000000000000000000..6bb8a70471e052d875f5651c95323b0840be024a
--- /dev/null
+++ b/config/urls.py
@@ -0,0 +1,18 @@
+"""Root URL configuration for android_unpack_platform."""
+
+from django.conf import settings
+from django.conf.urls.static import static
+from django.contrib import admin
+from django.urls import include, path
+
+urlpatterns = [
+    path('admin/', admin.site.urls),
+    path('', include('dashboard.urls', namespace='dashboard')),
+    path('samples/', include('apps.samples.urls', namespace='samples')),
+    path('task-ops/', include('apps.task_ops.urls', namespace='task_ops')),
+    path('analysis/', include('apps.analysis.urls', namespace='analysis')),
+    path('operations/', include('apps.operations.urls', namespace='operations')),
+]
+
+if settings.DEBUG:
+    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
diff --git a/config/wsgi.py b/config/wsgi.py
new file mode 100644
index 0000000000000000000000000000000000000000..5627ce56fe46112badc509ab5a62f19ea4e9ae1f
--- /dev/null
+++ b/config/wsgi.py
@@ -0,0 +1,9 @@
+"""WSGI config for android_unpack_platform."""
+
+import os
+
+from django.core.wsgi import get_wsgi_application
+
+os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
+
+application = get_wsgi_application()
diff --git a/dashboard/__init__.py b/dashboard/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/dashboard/apps.py b/dashboard/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..42be8177488205a2f87401b607d16911f37a5ce2
--- /dev/null
+++ b/dashboard/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class DashboardConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'dashboard'
+    verbose_name = '仪表盘'
diff --git a/dashboard/urls.py b/dashboard/urls.py
new file mode 100644
index 0000000000000000000000000000000000000000..cd1bcada75c536a7e10bc7fc5e8ba279375f8081
--- /dev/null
+++ b/dashboard/urls.py
@@ -0,0 +1,9 @@
+from django.urls import path
+
+from dashboard.views import health
+
+app_name = 'dashboard'
+
+urlpatterns = [
+    path('', health, name='health'),
+]
diff --git a/dashboard/views.py b/dashboard/views.py
new file mode 100644
index 0000000000000000000000000000000000000000..8f2590ceed5601a3ebc875bd403ff13aca39b754
--- /dev/null
+++ b/dashboard/views.py
@@ -0,0 +1,5 @@
+from django.http import HttpResponse
+
+
+def health(request):
+    return HttpResponse('android_unpack_platform is running')
diff --git a/docker-compose.yml b/docker-compose.yml
new file mode 100644
index 0000000000000000000000000000000000000000..be81a0a20ffcd4d2eb5be77bc4786ab69b5f95d6
--- /dev/null
+++ b/docker-compose.yml
@@ -0,0 +1,14 @@
+version: '3.9'
+services:
+  postgres:
+    image: postgres:16
+    environment:
+      POSTGRES_DB: android_unpack_platform
+      POSTGRES_USER: postgres
+      POSTGRES_PASSWORD: postgres
+    ports:
+      - '5432:5432'
+  redis:
+    image: redis:7
+    ports:
+      - '6379:6379'
diff --git a/execution/__init__.py b/execution/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/execution/apps.py b/execution/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..e5a058bcdb7cc7577abf487e8ee9f7b6f7c7007f
--- /dev/null
+++ b/execution/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class ExecutionConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'execution'
+    verbose_name = '执行引擎'
diff --git a/manage.py b/manage.py
new file mode 100755
index 0000000000000000000000000000000000000000..ab80d011c21fd4f8a0fd2242a868f06bc5ddf8be
--- /dev/null
+++ b/manage.py
@@ -0,0 +1,23 @@
+#!/usr/bin/env python
+"""Django's command-line utility for administrative tasks."""
+
+import os
+import sys
+
+
+def main() -> None:
+    """Run administrative tasks."""
+    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
+    try:
+        from django.core.management import execute_from_command_line
+    except ImportError as exc:
+        raise ImportError(
+            "Couldn't import Django. Are you sure it's installed and available on your "
+            "PYTHONPATH environment variable? Did you forget to activate a virtual "
+            "environment?"
+        ) from exc
+    execute_from_command_line(sys.argv)
+
+
+if __name__ == '__main__':
+    main()
diff --git a/requirements.txt b/requirements.txt
new file mode 100644
index 0000000000000000000000000000000000000000..6bbb16663d23fe1bbd42e3052b4b8a05d1542805
--- /dev/null
+++ b/requirements.txt
@@ -0,0 +1,5 @@
+Django==5.1.6
+psycopg2-binary==2.9.10
+redis==5.2.1
+celery==5.4.0
+apkutils2==1.0.0
diff --git a/samples/__init__.py b/samples/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/samples/apps.py b/samples/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..cdbd6ac82e99049ddaed1c2a1bf88f9d0f8b642e
--- /dev/null
+++ b/samples/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class SamplesConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'samples'
+    verbose_name = '样本管理'
diff --git a/shell_detector/__init__.py b/shell_detector/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/shell_detector/apps.py b/shell_detector/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..05b6893e55be69c1835e2faac5bd2bf8a31bc789
--- /dev/null
+++ b/shell_detector/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class ShellDetectorConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'shell_detector'
+    verbose_name = '壳识别'
diff --git a/task_ops/__init__.py b/task_ops/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/task_ops/apps.py b/task_ops/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..b55735ef78a6d73dbd4a9762b6722159221bb686
--- /dev/null
+++ b/task_ops/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class TaskOpsConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'task_ops'
+    verbose_name = '任务运维'
diff --git a/templates/analysis/task_detail.html b/templates/analysis/task_detail.html
new file mode 100644
index 0000000000000000000000000000000000000000..8ef9b73286b413518257bb2bdfd1afe8e6b23ea6
--- /dev/null
+++ b/templates/analysis/task_detail.html
@@ -0,0 +1,28 @@
+{% extends 'base.html' %}
+{% block content %}
+<h2>任务详情 #{{ task.id }}</h2>
+<ul>
+    <li>样本: {{ task.sample.file_name }}</li>
+    <li>状态: {{ task.status }}</li>
+    <li>策略: {{ task.strategy }}</li>
+    <li>识壳类型: {{ task.shell_type }}</li>
+    <li>产物: {{ task.result_artifact }}</li>
+    <li>错误: {{ task.error_message }}</li>
+    <li>人工复核: {{ task.requires_manual_review }}</li>
+    <li>复核备注: {{ task.review_note }}</li>
+</ul>
+
+<h3>事件日志</h3>
+<ul>
+{% for evt in task.events.all %}
+    <li>[{{ evt.created_at }}] {{ evt.old_status }} -> {{ evt.new_status }} | {{ evt.message }}</li>
+{% empty %}
+    <li>暂无事件</li>
+{% endfor %}
+</ul>
+
+<form method="post" action="/analysis/tasks/{{ task.id }}/retry/">
+    {% csrf_token %}
+    <button type="submit">重试任务</button>
+</form>
+{% endblock %}
diff --git a/templates/base.html b/templates/base.html
new file mode 100644
index 0000000000000000000000000000000000000000..9bc6608f8329c31658d3088d53dca7f59efcbe68
--- /dev/null
+++ b/templates/base.html
@@ -0,0 +1,28 @@
+<!DOCTYPE html>
+<html lang="zh-CN">
+<head>
+    <meta charset="UTF-8">
+    <title>Android Unpack Platform</title>
+    <style>
+        body { font-family: Arial, sans-serif; margin: 20px; }
+        nav a { margin-right: 12px; }
+        table { border-collapse: collapse; width: 100%; margin-top: 16px; }
+        th, td { border: 1px solid #ddd; padding: 8px; }
+    </style>
+</head>
+<body>
+<nav>
+    <a href="/">任务运维视图</a>
+    <a href="/samples/upload/">上传 APK</a>
+    <a href="/admin/">Admin</a>
+</nav>
+{% if messages %}
+<ul>
+    {% for message in messages %}
+        <li>{{ message }}</li>
+    {% endfor %}
+</ul>
+{% endif %}
+{% block content %}{% endblock %}
+</body>
+</html>
diff --git a/templates/operations/task_list.html b/templates/operations/task_list.html
new file mode 100644
index 0000000000000000000000000000000000000000..9ec5cd49a46548d501b4c244c88172c524c49f89
--- /dev/null
+++ b/templates/operations/task_list.html
@@ -0,0 +1,42 @@
+{% extends 'base.html' %}
+{% block content %}
+<h2>任务运维视图</h2>
+<form method="get">
+    <label>状态过滤:</label>
+    <input type="text" name="status" value="{{ current_status }}" placeholder="例如 SUCCESS" />
+    <button type="submit">过滤</button>
+</form>
+
+<h3>状态统计</h3>
+<ul>
+    {% for row in task_stats %}
+    <li>{{ row.status }}: {{ row.total }}</li>
+    {% empty %}
+    <li>暂无任务</li>
+    {% endfor %}
+</ul>
+
+<table>
+    <thead>
+        <tr>
+            <th>ID</th><th>样本</th><th>状态</th><th>策略</th><th>人工复核</th><th>重试</th><th>创建时间</th><th>操作</th>
+        </tr>
+    </thead>
+    <tbody>
+    {% for task in tasks %}
+        <tr>
+            <td>{{ task.id }}</td>
+            <td>{{ task.sample.file_name }}</td>
+            <td>{{ task.status }}</td>
+            <td>{{ task.strategy }}</td>
+            <td>{{ task.requires_manual_review }}</td>
+            <td>{{ task.retry_count }}/{{ task.max_retries }}</td>
+            <td>{{ task.created_at }}</td>
+            <td><a href="/analysis/tasks/{{ task.id }}/">详情</a></td>
+        </tr>
+    {% empty %}
+        <tr><td colspan="8">暂无任务</td></tr>
+    {% endfor %}
+    </tbody>
+</table>
+{% endblock %}
diff --git a/templates/samples/detail.html b/templates/samples/detail.html
new file mode 100644
index 0000000000000000000000000000000000000000..36e85bc4cfb4de346a0dcae1cbf57de920f59fa0
--- /dev/null
+++ b/templates/samples/detail.html
@@ -0,0 +1,35 @@
+{% extends 'base.html' %}
+
+{% block content %}
+<h2>样本详情 #{{ sample.id }}</h2>
+<ul>
+    <li>文件名: {{ sample.file_name }}</li>
+    <li>文件大小: {{ sample.file_size }}</li>
+    <li>SHA256: {{ sample.sha256 }}</li>
+    <li>包名: {{ sample.package_name|default:'-' }}</li>
+    <li>version_name: {{ sample.version_name|default:'-' }}</li>
+    <li>version_code: {{ sample.version_code|default:'-' }}</li>
+    <li>上传时间: {{ sample.uploaded_at }}</li>
+</ul>
+
+<h3>壳识别结果</h3>
+{% if detection %}
+<ul>
+    <li>shell_type: {{ detection.shell_type }}</li>
+    <li>confidence: {{ detection.confidence }}</li>
+    <li>evidence: {{ detection.evidence }}</li>
+    <li>strategy: {{ detection.strategy }}</li>
+    <li>command: {{ detection.command }}</li>
+    <li>exit_code: {{ detection.exit_code }}</li>
+    <li>error_message: {{ detection.error_message|default:'-' }}</li>
+</ul>
+<details>
+    <summary>raw_output</summary>
+    <pre>{{ detection.raw_output|safe }}</pre>
+</details>
+{% else %}
+<p>暂无识壳数据。</p>
+{% endif %}
+
+<p><a href="{% url 'samples:upload_apk' %}">继续上传</a></p>
+{% endblock %}
diff --git a/templates/samples/upload.html b/templates/samples/upload.html
new file mode 100644
index 0000000000000000000000000000000000000000..454fa8cb85741ea80ef3fc0772510b389e01aee1
--- /dev/null
+++ b/templates/samples/upload.html
@@ -0,0 +1,12 @@
+{% extends 'base.html' %}
+
+{% block content %}
+<h2>上传 APK</h2>
+<p>仅支持 .apk 文件，系统会自动校验、提取信息并执行 APKiD 识壳。</p>
+
+<form method="post" enctype="multipart/form-data">
+    {% csrf_token %}
+    {{ form.as_p }}
+    <button type="submit">上传并识别</button>
+</form>
+{% endblock %}
diff --git a/templates/task_ops/task_detail.html b/templates/task_ops/task_detail.html
new file mode 100644
index 0000000000000000000000000000000000000000..a0ee52a41b121ec20ab97ced9b2639d230f35a54
--- /dev/null
+++ b/templates/task_ops/task_detail.html
@@ -0,0 +1,75 @@
+{% extends "base.html" %}
+
+{% block content %}
+<h2>任务详情 #{{ job.id }}</h2>
+
+<div style="display:flex; gap:20px; flex-wrap: wrap;">
+    <div>
+        <h4>基础信息</h4>
+        <ul>
+            <li>样本文件: {{ job.sample.file_name }}</li>
+            <li>状态: {{ job.status }}</li>
+            <li>策略: {{ job.strategy }}</li>
+            <li>壳类型: {{ job.shell_detection.shell_type|default:'-' }}</li>
+            <li>识别置信度: {{ job.shell_detection.confidence|default:'-' }}</li>
+            <li>重试次数: {{ job.retry_count }}/{{ job.max_retries }}</li>
+            <li>执行节点: {{ job.result_summary.execution_node|default:'default-node' }}</li>
+            <li>模拟器实例: {{ job.result_summary.emulator_instance|default:'-' }}</li>
+            <li>开始时间: {{ job.started_at|default:'-' }}</li>
+            <li>结束时间: {{ job.finished_at|default:'-' }}</li>
+            <li>总耗时: {{ total_duration }}</li>
+            <li>产物目录: {{ job.artifact_dir|default:'-' }}</li>
+            <li>错误信息: {{ job.error_message|default:'-' }}</li>
+            <li>人工复核: {{ job.requires_review }}</li>
+        </ul>
+    </div>
+
+    <div>
+        <h4>策略与识壳</h4>
+        {% if job.shell_detection %}
+            <p><strong>evidence:</strong> {{ job.shell_detection.evidence }}</p>
+            <details>
+                <summary>raw_output</summary>
+                <pre>{{ job.shell_detection.raw_output|safe }}</pre>
+            </details>
+        {% else %}
+            <p>暂无识壳信息。</p>
+        {% endif %}
+    </div>
+</div>
+
+<h3>状态时间线</h3>
+<table>
+    <thead>
+        <tr>
+            <th>时间</th>
+            <th>阶段</th>
+            <th>级别</th>
+            <th>消息</th>
+            <th>距上一阶段</th>
+        </tr>
+    </thead>
+    <tbody>
+        {% for item in timeline %}
+            <tr>
+                <td>{{ item.time }}</td>
+                <td>{{ item.stage }}</td>
+                <td>{{ item.level }}</td>
+                <td>{{ item.message }}</td>
+                <td>{{ item.elapsed_since_previous|default:'-' }}</td>
+            </tr>
+        {% empty %}
+            <tr><td colspan="5">暂无时间线数据</td></tr>
+        {% endfor %}
+    </tbody>
+</table>
+
+<div style="margin-top: 14px;">
+    <a href="{% url 'task_ops:task_logs' job.id %}">查看全部日志</a>
+</div>
+
+<div style="margin-top: 14px; display:flex; gap:10px;">
+    <button type="button" disabled>失败重试（预留）</button>
+    <button type="button" disabled>人工复核（预留）</button>
+</div>
+{% endblock %}
diff --git a/templates/task_ops/task_list.html b/templates/task_ops/task_list.html
new file mode 100644
index 0000000000000000000000000000000000000000..aa25109b23d0ede9a052287d440d0818060dd5f7
--- /dev/null
+++ b/templates/task_ops/task_list.html
@@ -0,0 +1,108 @@
+{% extends "base.html" %}
+
+{% block content %}
+<h2>任务运维视图</h2>
+
+<form method="get" style="margin-bottom: 16px; display: flex; gap: 8px; flex-wrap: wrap;">
+    <select name="status">
+        <option value="">全部状态</option>
+        {% for value, label in status_choices %}
+            <option value="{{ value }}" {% if filters.status == value %}selected{% endif %}>{{ value }} / {{ label }}</option>
+        {% endfor %}
+    </select>
+
+    <input type="text" name="shell_type" value="{{ filters.shell_type }}" placeholder="壳类别(模糊)" />
+
+    <select name="strategy">
+        <option value="">全部策略</option>
+        {% for value, label in strategy_choices %}
+            <option value="{{ value }}" {% if filters.strategy == value %}selected{% endif %}>{{ value }} / {{ label }}</option>
+        {% endfor %}
+    </select>
+
+    <input type="text" name="user" value="{{ filters.user }}" placeholder="用户(上传人)" />
+    <button type="submit">筛选</button>
+    <a href="{% url 'task_ops:task_list' %}">重置</a>
+</form>
+
+<div style="display:flex; gap:24px; margin-bottom:12px;">
+    <div>
+        <h4>状态统计</h4>
+        <ul>
+            {% for row in status_stats %}
+                <li>{{ row.status }}: {{ row.total }}</li>
+            {% empty %}
+                <li>暂无数据</li>
+            {% endfor %}
+        </ul>
+    </div>
+    <div>
+        <h4>壳类别 Top10</h4>
+        <ul>
+            {% for row in shell_stats %}
+                <li>{{ row.shell_detection__shell_type|default:'UNKNOWN' }}: {{ row.total }}</li>
+            {% empty %}
+                <li>暂无数据</li>
+            {% endfor %}
+        </ul>
+    </div>
+</div>
+
+<table>
+    <thead>
+        <tr>
+            <th>ID</th>
+            <th>样本</th>
+            <th>状态</th>
+            <th>壳类别</th>
+            <th>策略</th>
+            <th>执行节点</th>
+            <th>模拟器实例</th>
+            <th>重试</th>
+            <th>耗时</th>
+            <th>错误</th>
+            <th>操作</th>
+        </tr>
+    </thead>
+    <tbody>
+        {% for job in page_obj.object_list %}
+            <tr>
+                <td>{{ job.id }}</td>
+                <td>{{ job.sample.file_name }}</td>
+                <td>{{ job.status }}</td>
+                <td>{{ job.shell_detection.shell_type|default:'-' }}</td>
+                <td>{{ job.strategy }}</td>
+                <td>{{ job.result_summary.execution_node|default:'default-node' }}</td>
+                <td>{{ job.result_summary.emulator_instance|default:'-' }}</td>
+                <td>{{ job.retry_count }}/{{ job.max_retries }}</td>
+                <td>
+                    {% if job.started_at and job.finished_at %}
+                        {{ job.finished_at|timesince:job.started_at }}
+                    {% elif job.started_at %}
+                        进行中
+                    {% else %}
+                        -
+                    {% endif %}
+                </td>
+                <td>{{ job.error_message|default:'-'|truncatechars:50 }}</td>
+                <td>
+                    <a href="{% url 'task_ops:task_detail' job.id %}">详情</a> |
+                    <a href="{% url 'task_ops:task_logs' job.id %}">日志</a>
+                </td>
+            </tr>
+        {% empty %}
+            <tr><td colspan="11">暂无任务</td></tr>
+        {% endfor %}
+    </tbody>
+</table>
+
+<div style="margin-top: 12px;">
+    {% if page_obj.has_previous %}
+        <a href="?page={{ page_obj.previous_page_number }}&status={{ filters.status }}&shell_type={{ filters.shell_type }}&strategy={{ filters.strategy }}&user={{ filters.user }}">上一页</a>
+    {% endif %}
+    <span>第 {{ page_obj.number }} / {{ page_obj.paginator.num_pages }} 页</span>
+    {% if page_obj.has_next %}
+        <a href="?page={{ page_obj.next_page_number }}&status={{ filters.status }}&shell_type={{ filters.shell_type }}&strategy={{ filters.strategy }}&user={{ filters.user }}">下一页</a>
+    {% endif %}
+</div>
+{% endblock %}
diff --git a/templates/task_ops/task_logs.html b/templates/task_ops/task_logs.html
new file mode 100644
index 0000000000000000000000000000000000000000..ce2195181b765c352af60a67c544badbbed0c713
--- /dev/null
+++ b/templates/task_ops/task_logs.html
@@ -0,0 +1,65 @@
+{% extends "base.html" %}
+
+{% block content %}
+<h2>任务日志 #{{ job.id }}</h2>
+
+<form method="get" style="display:flex; gap:8px; margin-bottom:12px;">
+    <select name="level">
+        <option value="">全部级别</option>
+        {% for value in level_choices %}
+            <option value="{{ value }}" {% if value == level %}selected{% endif %}>{{ value }}</option>
+        {% endfor %}
+    </select>
+    <input type="text" name="stage" value="{{ stage }}" placeholder="阶段(模糊)" />
+    <button type="submit">筛选</button>
+    <a href="{% url 'task_ops:task_logs' job.id %}">重置</a>
+</form>
+
+<table>
+    <thead>
+        <tr>
+            <th>时间</th>
+            <th>级别</th>
+            <th>阶段</th>
+            <th>消息</th>
+            <th>数据</th>
+        </tr>
+    </thead>
+    <tbody>
+        {% for log in page_obj.object_list %}
+            <tr>
+                <td>{{ log.created_at }}</td>
+                <td>{{ log.level }}</td>
+                <td>{{ log.stage }}</td>
+                <td>{{ log.message }}</td>
+                <td>
+                    {% if log.data %}
+                        <details>
+                            <summary>查看</summary>
+                            <pre>{{ log.data|safe }}</pre>
+                        </details>
+                    {% else %}
+                        -
+                    {% endif %}
+                </td>
+            </tr>
+        {% empty %}
+            <tr><td colspan="5">暂无日志</td></tr>
+        {% endfor %}
+    </tbody>
+</table>
+
+<div style="margin-top: 12px;">
+    {% if page_obj.has_previous %}
+        <a href="?page={{ page_obj.previous_page_number }}&level={{ level }}&stage={{ stage }}">上一页</a>
+    {% endif %}
+    <span>第 {{ page_obj.number }} / {{ page_obj.paginator.num_pages }} 页</span>
+    {% if page_obj.has_next %}
+        <a href="?page={{ page_obj.next_page_number }}&level={{ level }}&stage={{ stage }}">下一页</a>
+    {% endif %}
+</div>
+
+<div style="margin-top: 12px;">
+    <a href="{% url 'task_ops:task_detail' job.id %}">返回任务详情</a>
+</div>
+{% endblock %}
diff --git a/unpack_tasks/__init__.py b/unpack_tasks/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/unpack_tasks/apps.py b/unpack_tasks/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..3adafc00f80a085c730e1ec7728cb44c0c2f5470
--- /dev/null
+++ b/unpack_tasks/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class UnpackTasksConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'unpack_tasks'
+    verbose_name = '脱壳任务'
diff --git a/users/__init__.py b/users/__init__.py
new file mode 100644
index 0000000000000000000000000000000000000000..e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
diff --git a/users/apps.py b/users/apps.py
new file mode 100644
index 0000000000000000000000000000000000000000..d0598bb04cf322d4ff1b6a13ccba7c62d8534426
--- /dev/null
+++ b/users/apps.py
@@ -0,0 +1,7 @@
+from django.apps import AppConfig
+
+
+class UsersConfig(AppConfig):
+    default_auto_field = 'django.db.models.BigAutoField'
+    name = 'users'
+    verbose_name = '用户中心'
 
EOF
)
