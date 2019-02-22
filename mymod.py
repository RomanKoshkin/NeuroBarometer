from URL_download_2 import gdown

def myfunc():
    file_id = '1fsRRSP8KuDU_pGh75CPuYJbkm-qQpzOp' # NeoRec_2018-07-05_15-33-44.vmrk


    # instantiate class (create a class instance):
    G = gdown()

    # Download data from Google Drive as necessary:
    G.download_file(file_id)
    return 'version 1'