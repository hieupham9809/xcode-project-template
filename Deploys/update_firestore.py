# update_firestore.py

from google.cloud import firestore
import sys

def update_download_url(project_id, collection, document, download_url):
    # Initialize Firestore client
    db = firestore.Client(project=project_id)
    
    # Reference to the document
    doc_ref = db.collection(collection).document(document)
    
    # Update the document
    doc_ref.update({
        'url': download_url
    })
    print(f"Firestore document {document} in collection {collection} updated with URL: {download_url}")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python update_firestore.py <project_id> <collection> <document> <download_url>")
        sys.exit(1)
    
    project_id = sys.argv[1]
    collection = sys.argv[2]
    document = sys.argv[3]
    download_url = sys.argv[4]
    
    update_download_url(project_id, collection, document, download_url)