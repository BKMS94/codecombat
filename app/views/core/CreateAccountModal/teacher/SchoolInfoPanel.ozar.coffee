require 'app/styles/modal/create-account-modal/school-info-panel.sass'
NcesSearchInput = require './NcesSearchInput'
algolia = require 'core/services/algolia'
DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students']
SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students', 'phone'])
countryList = require('country-list')()
UsaStates = require('usa-states').UsaStates
# NOTE: Phone number in algolia search results is for a school, not a district

SchoolInfoPanel =
  name: 'school-info-panel'
  template: require('app/templates/core/create-account-modal/school-info-panel')()

  data: ->
    # TODO: Store ncesData in just the store?
    ncesData = _.zipObject(['nces_'+key, ''] for key in SCHOOL_NCES_KEYS)
    formData = _.pick(@$store.state.modal.trialRequestProperties,
      ('nces_'+key for key in SCHOOL_NCES_KEYS).concat [
        'organization'
        'district'
        'city'
        'state'
        'country'
      ])

    return _.assign(ncesData, formData, {
      showRequired: false
      countries: countryList.getNames()
      usaStates: new UsaStates().states
      usaStatesAbbreviations: new UsaStates().arrayOf('abbreviations')
      countryMap:
        "Hong Kong": "Hong Kong, China",
        "Macao": "Macao, China",
        "Taiwan, Province of China": "Taiwan, China"
    })

  components:
    'nces-search-input': NcesSearchInput

  methods:
    updateValue: (name, value) ->
      @[name] = value
      # Clear relevant NCES fields if they type a custom value instead of an autocompleted value
      if name is 'organization'
        @clearSchoolNcesValues()
      if name is 'district'
        @clearSchoolNcesValues()
        @clearDistrictNcesValues()

    clearDistrictNcesValues: ->
      for key in DISTRICT_NCES_KEYS
        @['nces_' + key] = ''

    clearSchoolNcesValues: ->
      for key in _.difference(SCHOOL_NCES_KEYS, DISTRICT_NCES_KEYS)
        @['nces_' + key] = ''

    applySuggestion: (displayKey, suggestion) ->
      return unless suggestion
      _.assign(@, _.pick(suggestion, 'district', 'city', 'state'))
      if displayKey is 'name'
        @organization = suggestion.name
      @country = 'United States'
      @clearSchoolNcesValues()
      @clearDistrictNcesValues()
      NCES_KEYS = if displayKey is 'name' then SCHOOL_NCES_KEYS else DISTRICT_NCES_KEYS
      for key in NCES_KEYS
        @['nces_'+key] = suggestion[key]

    onChangeCountry: ->
      if @['country'] == 'United States' && !@usaStatesAbbreviations.includes(@['state'])
        @['state'] = ''

    commitValues: ->
      attrs = _.pick(@, 'organization', 'district', 'city', 'state', 'country')
      for key in SCHOOL_NCES_KEYS
        ncesKey = 'nces_'+key
        attrs[ncesKey] = @[ncesKey].toString()
      @$store.commit('modal/updateTrialRequestProperties', attrs)

    clickContinue: ->
      # Make sure to add conditions if we change this to be used on non-teacher path
      window.tracker?.trackEvent 'CreateAccountModal Teacher SchoolInfoPanel Continue Clicked', category: 'Teachers'
      requiredAttrs = _.pick(@, 'district', 'city', 'state', 'country')
      unless _.all(requiredAttrs)
        @showRequired = true
        return
      @commitValues()
      window.tracker?.trackEvent 'CreateAccountModal Teacher SchoolInfoPanel Continue Success', category: 'Teachers'
      @$emit('continue')

    clickBack: ->
      @commitValues()
      window.tracker?.trackEvent 'CreateAccountModal Teacher SchoolInfoPanel Back Clicked', category: 'Teachers'
      @$emit('back')

  mounted: ->
    $("input[name*='organization']").focus()

module.exports = SchoolInfoPanel
