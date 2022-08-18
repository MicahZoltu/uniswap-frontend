import { Trans } from '@lingui/macro'
import { Currency, Percent, TradeType } from '@uniswap/sdk-core'
import { ReactNode } from 'react'
import { Text } from 'rebass'
import { InterfaceTrade } from 'state/routing/types'

import { ButtonError } from '../Button'
import { AutoRow } from '../Row'
import { SwapCallbackError } from './styleds'

export default function SwapModalFooter({
  trade,
  allowedSlippage,
  txHash,
  onConfirm,
  swapErrorMessage,
  disabledConfirm,
  swapQuoteReceivedDate,
}: {
  trade: InterfaceTrade<Currency, Currency, TradeType>
  txHash: string | undefined
  allowedSlippage: Percent
  onConfirm: () => void
  swapErrorMessage: ReactNode | undefined
  disabledConfirm: boolean
  swapQuoteReceivedDate: Date | undefined
}) {
  return (
    <>
      <AutoRow>
        <ButtonError
          onClick={onConfirm}
          disabled={disabledConfirm}
          style={{ margin: '10px 0 0 0' }}
          id="confirm-swap-or-send"
        >
          <Text fontSize={20} fontWeight={500}>
            <Trans>Confirm Swap</Trans>
          </Text>
        </ButtonError>

        {swapErrorMessage ? <SwapCallbackError error={swapErrorMessage} /> : null}
      </AutoRow>
    </>
  )
}
