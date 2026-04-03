from django import forms


class APKUploadForm(forms.Form):
    file = forms.FileField(label='APK 文件')

    def clean_file(self):
        file = self.cleaned_data['file']
        if not file.name.lower().endswith('.apk'):
            raise forms.ValidationError('仅支持 .apk 文件。')
        return file
