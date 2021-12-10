# pre-requirements:
# python 2.7
# update '/users/...' paths
# update certificate & provision

import pprint
import simples3
import glob
import os
from xml.dom import minidom
import subprocess
import datetime
import urllib
import urllib2
import sys
import datetime
import traceback
import requests
import plistlib
import shutil
from poster.encode import multipart_encode
from poster.streaminghttp import register_openers
from time import gmtime, strftime


def all_files_under(path, suffix):
    """Iterates through all files that are under the given path."""
    for cur_path, dirnames, filenames in os.walk(path):
        for dirname in dirnames:
            if dirname.endswith(suffix):
                yield os.path.join(cur_path, dirname)


register_openers()

major_version = '2.00'
custom_release_notes = ''

# os.chdir('/Volumes/Data/Development/iPhone/Mobli3')
HOME = os.environ.get('HOME')

### Define the targets here ###

target_inhouse = {
    'signing_identity': 'iPhone Distribution: O. Arbel Technologies LTD',
    'provisioning_profile': 'YoEnterpriseDist',
    'product_name': 'YoInHouse',
    'target_name': 'YoInHouse',
    's3_path': 'yo/yo.ipa',
    'info_plist': 'Yo/YoInHouse-Info.plist',
    'upload_to_s3': True
}

targets = [target_inhouse]


def zipdir(path, zip):
    for root, dirs, files in os.walk(path):
        for file in files:
            zip.write(file)


def mail(to, subject, text, attach):

    import smtplib
    from email.MIMEMultipart import MIMEMultipart
    from email.MIMEBase import MIMEBase
    from email.MIMEText import MIMEText
    from email import Encoders
    import os

    gmail_user = ''
    gmail_pwd = ''

    msg = MIMEMultipart()

    msg['From'] = gmail_user
    msg['To'] = to
    msg['Subject'] = subject

    msg.attach(MIMEText(''))
    part = MIMEBase('application', 'octet-stream')
    part.set_payload(open(attach, 'rb').read())
    Encoders.encode_base64(part)
    part.add_header('Content-Disposition',
                    'attachment; filename="%s"' % os.path.basename(attach))
    msg.attach(part)

    mailServer = smtplib.SMTP("smtp.gmail.com", 587)
    mailServer.ehlo()
    mailServer.starttls()
    mailServer.ehlo()
    mailServer.login(gmail_user, gmail_pwd)
    mailServer.sendmail(gmail_user, to, msg.as_string())
    mailServer.close()

#######################################################

rootdir = os.path.realpath('')

##########################################################################


def deploy(target):

   ###################### Bump build number  #########

    plist = plistlib.readPlist('./' + target['info_plist'])
    version = plist['CFBundleVersion']
    splitted = version.split('.')
    major = splitted[0]
    minor = splitted[1]
    patch = splitted[2]

    print target['target_name'] + ': ' + 'Current build number: ' + patch

    if any('--dont-build' in s for s in sys.argv):
        bumped = patch
        print 'Skipped bumping'
    else:
        bumped = str(int(patch) + 1)

    print target['target_name'] + ': ' + 'Bumped build number: ' + bumped

    new_version_num = major + '.' + minor + '.' + bumped

    plist['CFBundleVersion'] = new_version_num
    plistlib.writePlist(plist, './' + target['info_plist'])

    print target['target_name'] + ': ' + 'Building target: ' + target['target_name']

    ###################### Build Target #################################

    # ret = os.system('xcodebuild clean -project Mobli.xcodeproj -target "' + target['target_name'] + '" >
        #/dev/null') # clean before building
    # if not ret == 0:
    #   print target['target_name'] + ': ' + 'Clean failed'
    #   return

    if any('--dont-build' in s for s in sys.argv):
        print 'Skipping build'
    else:

        now = datetime.datetime.now()
        today = now.strftime("%Y-%m-%d")
        archive_folder = HOME + '/Library/Developer/Xcode/Archives/' + today + '/'
        archive_path = archive_folder + 'Yo.xcarchive'

        ret = os.system('xcodebuild -workspace Yo.xcworkspace/ \
                                    -destination generic/platform=iOS \
                                    -scheme ' + target['target_name'] + ' \
                                    -archivePath "' + archive_path + '" archive')
        if not ret == 0:
            print target['target_name'] + ': ' + 'Build failed'
            return

        print target['target_name'] + ': ' + 'Building success'
        print 'Archived into: ' + archive_path

    ###################### Create IPA #################################

    print target['target_name'] + ': ' + 'Creating IPA...'

    dst_build_dir = '/build/'

    ipa_filename = target['target_name'] + "-" + new_version_num + ".ipa"

    dst_ipa_path = rootdir + dst_build_dir + ipa_filename

    os.system('rm -rf ' + dst_ipa_path)

    print 'Build IPA at: ' + dst_ipa_path

    if not any('--dont-build' in s for s in sys.argv):

        ret = os.system('xcodebuild -exportArchive \
                                    -exportFormat ipa \
                                    -archivePath "' + archive_path + '" \
                                    -exportPath "' + dst_ipa_path + '" \
                                    -exportProvisioningProfile "' + target['provisioning_profile'] + '" \
                                    CODE_SIGN_IDENTITY="' + target['signing_identity'] + '"')

        if not ret == 0:
            print target['target_name'] + ': ' + 'PackageApplication failed'
            return

        print target['target_name'] + ': ' + 'Created IPA at: ' + dst_ipa_path

    ######################## Upload build to S3 ##############################

    if target['upload_to_s3']:

        print target['target_name'] + ': ' + 'Uploading to S3...'

        ipa_file = open(dst_ipa_path)

        s = simples3.S3Bucket(name='yoapp',
                              access_key='AKIAJOEZMW2CP7TLHDEQ',
                              secret_key='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',
                              base_url='https://yoapp.s3.amazonaws.com')
        s.put(target['s3_path'], ipa_file.read(), acl="public-read")

        ipa_file.close()

        print target['target_name'] + ': ' + 'Uploaded to S3!'

        text_for_slack = '@everyone New beta (' + new_version_num + ') is up on http://justyo.co/ios'
        requests.post('https://hooks.slack.com/services/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',
                      json={"text": text_for_slack,  "icon_emoji": ":ghost:", "username": "YoBot"})

    ########################################################################

#################### Build Targets #############################

for target in targets:
    print deploy(target)

print 'All Done!'

#########################################################################
