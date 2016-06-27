# Desk.com Canvas: Drive
The **Desk.com Drive** is a canvas application that adds file management to cases. It allows you to upload, download and share files to and from [Dropbox.com](https://dropbox.com), [Google Drive](https://drive.google.com) and many more.

## I. Deploy the Application
First, install this application by deploying the source code to your Heroku account. To deploy your application, simply click this button:

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https%3A%2F%2Fgithub.com%2Fdesklabs%2Fcanvas-drive)

## II. Create the Integration URL
Now that you have the application on Heroku, go ahead and create the integration URL.

1. In the **Name** field, add a title for the this application. In this example, we’ll you use 'File Explorer'.

2. The **Description** field, though optional, is a way to give a general description of the integration URL.

3. Select 'Canvas iFrame' from the **Open Location** dropdown.

4. In the **URL** field, add the Heroku URL with a "/login" in the end.

5. Toggle the **Enabled** button to 'Yes' and select the [Permission level](https://support.desk.com/customer/portal/articles/1146981?b_id=7112&t=568640).

6. Click the **Update** button.

7. Make note of the **Shared Key** when you create the Integration URL.

![Integration URL](https://api.monosnap.com/rpc/file/download?id=EEe0KD3qbB2xaRMJDcqUruwtuOiDWT)

## III. Finish up the setup of the Application

1. If you clicked the **View** button after deploying the application to Heroku you should alread see the login screen otherwise go to your Heroku URL and add "/admin" to the end.

2. The login credentials are the same as your Heroku credentials as we manage Heroku environmental variables for this application.

3. When you're logged in fill out all the information on the screen and hit save.

## IV. Add it to your Case Layout
Now display the canvas application on your Case Layout.

1. **Go to Cases >> Next Gen Case Layouts**

2. Find the **File Explorer** canvas application in the **Integrations** section on the right side of the screen.

3. **Drag** and **Drop** the application in your case layout.

4. Scroll over the left side of the 'Time Tracker' bar and click on the gear to open the **Edit** window. Adjust the pixel **Height** (e.g., 470) and **Position**, the order in which it appears in Case Details on the dashboard. Click **Save**.

![Case Layout](https://api.monosnap.com/rpc/file/download?id=pZuUDCz0vKMrXRDjFH9hCVcE1i53qh)

## V. Dashboard Confirmation
After you have added the canvas application to your layout and selected users, open a ticket and you should see the File Explorer under **Case Details**.

![Preview  Stopped](https://api.monosnap.com/rpc/file/download?id=b709jZIF9uFTYZhIM4gdJQfN8GtgZe)

![Preview  Started](https://api.monosnap.com/rpc/file/download?id=Ly4i9IjoAnnkrrrdqEyJ5njlZtKSDh)