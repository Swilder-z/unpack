from django.http import HttpResponse


def health(request):
    return HttpResponse('android_unpack_platform is running')
