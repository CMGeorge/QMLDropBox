import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.1

import "qrc:/oauth/OAuth.js" as OAuth

import QtDropBox2 1.0

Window {
    id: appWindow
    property alias dropBoxIntance: dropBoxIntance
    property alias busyIndicator:busyIndicator
    property variant pathList: [];

    function setLoading(statusLoading){
        busyIndicator.running = statusLoading
    }

    QDropbox2{
        id: dropBoxIntance
    }
    QDropbox2Folder{
        id: dropBoxFolder
        api: dropBoxIntance
    }
    QDropbox2File{
        id: fileDownloader
        api: dropBoxIntance
        onSignal_downloadProgress:{
//            console.debug("Progess "+bytesReceived+" from "+bytesTotal)
        }
        onSignal_errorOccurred:{
            console.debug("Error: "+errorcode+" with message "+errormessage)
        }
        onSignal_operationAborted:{
            console.debug("Operation Aborted");
        }
//        onSignal_downloadFinished:{
//            console.debug("Download Finished ")//<<fileDownloader.temporaryLink());
//        }

//        function downloadFile(filename){
//            fileDownloader.filename = filename
//            fileDownloader.downloadFile();
////            console.debug("Open File Status: "<<fileDownloader.openReadOnly());
//        }
    }

    visible: true
    width: 480
    height: 640
    title: qsTr("DropBox")
    onPathListChanged: {
        console.debug("Path List Changed")
        lblPath.text  = pathList.join("/")
    }

    ColumnLayout{
        anchors.fill: parent
        Button{
            text: "DropBox Authorisation"
            Layout.fillWidth: true
            onClicked: {
                OAuth.authoriseDropBox(appWindow,
                                       function (urlElements){
                                           console.debug("DROPBOX")
                                           console.debug("Success "+JSON.stringify(urlElements))
                                           var _accessToken = urlElements.access_token
                                            dropBoxSettings.accessToken = _accessToken;
                                           dropBoxIntance.setAccessToken(_accessToken);
                                           dropBoxFolder.foldername = ""
                                           dropBoxFolder.contents(listModel);
                                           //                                           listView.model = {};
                                           //                                           listView.model = listModel
                                           //                                          buttonAuthorise.visible = !DropBox.isAuthorised();
                                           //                                           getFiles();
                                           //                                           QDropbox2Folder folder;
                                       },
                                       function (errorMessage){
                                           console.debug("error "+errorMessage);
                                       })//outhPopup.open();
            }
        }
        RowLayout{
            Button{
                id: backButton
                text: "Back"
                visible: lblPath.text!=="";
                onClicked: {
                    pathList.pop();
                    lblPath.text  = pathList[pathList.length-1]!==undefined?pathList[pathList.length-1]:"";
                    dropBoxFolder.foldername = lblPath.text
                    dropBoxFolder.contents(listModel)
                }
            }
            Label{
                id: lblPath
                Layout.fillWidth: true
                text: pathList.join("/");
            }
            Button{
                id: refresh
                text: "Refresh";
                onClicked: {
                    dropBoxFolder.contents(listModel)
                }
            }
        }

        ListView{
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: FoldersModel{
                id: listModel
            }
            delegate: ItemDelegate{
                width: parent.width
                text: name
                //                Component.onCompleted: console.debug(model.filename());
                onClicked: {
                    if (model.isDirectory){
//                        setLoading(true)
                        pathList.push(path);
                        lblPath.text  = pathList[pathList.length-1];
                        dropBoxFolder.foldername = path
                        dropBoxFolder.contents(listModel)
//                        setLoading(false)
                    }else{

                        var _sprite = Qt.createQmlObject("import QtQuick 2.12;
import QtQuick.Dialogs 1.3;
MessageDialog {
    id: messageDialog;
    title: \"Download file\";
    text: \"Do you want do download "+name+"\";
    standardButtons: StandardButton.Yes | StandardButton.No

}",
                                                         appWindow)
                        _sprite.open();
                        _sprite.no.connect(function (){});
                        _sprite.yes.connect(function (){
                            busyIndicator.running = true
                            fileDownloader.filename = path
                            console.debug("Downloaded: "+fileDownloader.downloadFile());
                            busyIndicator.running = false;

                        })
                    }
                }
            }
        }
    }
    Component.onCompleted: {
        if (dropBoxSettings.accessToken!==""){
            dropBoxIntance.setAccessToken(dropBoxSettings.accessToken);
            dropBoxFolder.foldername = "/"
            dropBoxFolder.contents(listModel);
        }
    }

    Settings{
        id: dropBoxSettings
        category: "DropBox"
        property string accessToken:""
    }
    BusyIndicator{
        id: busyIndicator
        running: false
        anchors.centerIn: parent
    }
}
