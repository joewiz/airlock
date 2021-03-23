/* global cy */
describe('The landing page', function () {
  it ('should load ', function () {
    cy.visit('/exist/apps/airlock/')
      .contains('Airlock')
  })

})
