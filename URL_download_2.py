from googleapiclient import errors
from googleapiclient import http
from googleapiclient.discovery import build
from httplib2 import Http
from oauth2client import file, client, tools
import io

# from apiclient.http import MediaIoBaseDownload
from googleapiclient.http import MediaIoBaseDownload


class gdown(object):
    
    
    def __init__(self):
        super(gdown, self).__init__()
        self.SCOPES = 'https://www.googleapis.com/auth/drive.readonly'
        self.store = file.Storage('credentials.json')
        self.creds = self.store.get()
        if not self.creds or self.creds.invalid:
            self.aa = 'client_secret_801600220437-idodf25dmrlebalv0fa2hj5thql3ltv9.apps.googleusercontent.com.json'
            self.flow = client.flow_from_clientsecrets(self.aa, self.SCOPES)
            self.creds = tools.run_flow(self.flow, self.store)
            self.service = build('drive', 'v3', http=self.creds.authorize(Http()))


    def print_file_metadata(self, file_id):
        try:
            file = self.service.files().get(fileId=file_id).execute()
            print ('MIME type:', file['mimeType'])
        except errors.HttpError as error:
            print ('An error occurred:', error)

    def download_file(self, file_id):
        file = self.service.files().get(fileId=file_id).execute()
        file_name = file['name']
        print ('Name:', file_name)
        # print ('MIME type:', file['mimeType'])
        local_fd = open(file_name, "wb")
        request = self.service.files().get_media(fileId=file_id)
        media_request = http.MediaIoBaseDownload(local_fd, request)
    
        while True:
            try:
                download_progress, done = media_request.next_chunk()
            except errors.HttpError as error:
                print ('An error occurred:', error)
                return

            if download_progress:
                print ('Download Progress:', int(download_progress.progress() * 100))
            if done:
                print ('Download Complete')
                local_fd.close()
            return

    def ListGoogleDrive(self):
        results = service.files().list(pageSize=10, fields="nextPageToken, files(id, name)").execute()
        items = results.get('files', [])
    
        if not items:
            print('No files found.')
        else:
            print('Files:')
            for item in items:
                print('{0} ({1})'.format(item['name'], item['id']))