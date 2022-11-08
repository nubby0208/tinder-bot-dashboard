// Import all the channels to be used by Action Cable
// import "channels/logs_channel"
import * as ActionCable from '@rails/actioncable'
import consumer from "channels/consumer"
window.App || (window.App = {});
window.App.cable = ActionCable.createConsumer();
