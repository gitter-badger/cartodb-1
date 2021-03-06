/* Progress quota bar for organization users input */

module.exports = cdb.core.View.extend({

  events: {
    'keyup .js-assignedSize': '_onKeyup'
  },

  initialize: function() {
    this._initBinds();
    this._initViews();
  },

  _initBinds: function() {
    this.model.bind('change:quota_in_bytes', this._onQuotaChange, this);
  },

  _initViews: function() {
    var quotaInMb = Math.max(Math.floor(this.model.get('quota_in_bytes')/1024/1024).toFixed(0), 1);
    this.$('.js-assignedSize').val(quotaInMb);
  },

  _onQuotaChange: function() {
    this.$('.js-assignedSize').val(Math.max(Math.floor(this.model.get('quota_in_bytes')/1024/1024).toFixed(0), 1));
    this.$('.js-assignedSize').removeClass('FormAccount-input--error');
  },

  _onKeyup: function() {
    var modifiedQuotaInBytes = Math.max(Math.floor(this.$('.js-assignedSize').val() * 1048576), 1048576);
    var usedUserQuota = (this.model.get('db_size_in_bytes') * 100) / this.model.organization.get('available_quota_for_user');
    var assignedPer = (modifiedQuotaInBytes*100) / this.model.organization.get('available_quota_for_user');

    (isNaN(assignedPer) || (assignedPer <= usedUserQuota) || (assignedPer > 100)) ? this.$('.js-assignedSize').addClass('FormAccount-input--error') : this.$('.js-assignedSize').removeClass('FormAccount-input--error');

    if ((assignedPer >= usedUserQuota) && (assignedPer <= 100)) {
      this.model.set('quota_in_bytes', modifiedQuotaInBytes);
    }

  }

})